import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'classroom_chat_dock_models.dart';

/// Global controller for Messenger-style floating classroom chat.
class ClassroomChatDockController extends ChangeNotifier {
  ClassroomChatDockController({
    ClassroomChatRepository? chatRepo,
    SocketService? socket,
  })  : _chatRepo = chatRepo ?? getIt<ClassroomChatRepository>(),
        _socket = socket ?? getIt<SocketService>();

  final ClassroomChatRepository _chatRepo;
  final SocketService _socket;

  bool listPanelOpen = false;
  ClassroomChatSession? session;
  List<ClassroomChatRoomItem> rooms = const [];
  bool loadingRooms = false;
  String? roomsError;
  int unreadConversations = 0;

  bool _inboxSocketAttached = false;
  late void Function(dynamic) _inboxHandler;

  /// Cuộc trò chuyện đang mở và không thu nhỏ → không tăng unread.
  bool isActiveChat(String classroomId) {
    final s = session;
    return s != null && !s.minimized && s.classroomId == classroomId;
  }

  void attachInboxSocket() {
    if (_inboxSocketAttached) return;
    _inboxSocketAttached = true;
    _inboxHandler = _onInboxSocket;
    _socket.addClassroomInboxListener(_inboxHandler);
  }

  void detachInboxSocket() {
    if (!_inboxSocketAttached) return;
    _socket.removeClassroomInboxListener(_inboxHandler);
    _inboxSocketAttached = false;
  }

  void _notifyListenersSafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  Future<void> loadRooms({bool force = false}) async {
    if (loadingRooms) return;
    if (!force && rooms.isNotEmpty) return;

    loadingRooms = true;
    roomsError = null;
    _notifyListenersSafely();

    final result = await _chatRepo.getChatInbox();
    result.fold(
      (f) {
        roomsError = f.message;
        rooms = const [];
        unreadConversations = 0;
      },
      (raw) {
        final list = (raw['rooms'] as List?) ?? [];
        rooms = list
            .map((e) => _parseInboxRoom(Map<String, dynamic>.from(e as Map)))
            .where((r) => r.id.isNotEmpty)
            .toList();
        unreadConversations = (raw['unreadConversations'] as num?)?.toInt() ??
            rooms.where((r) => r.hasUnread).length;
        _sortRooms();
      },
    );

    loadingRooms = false;
    notifyListeners();
  }

  /// Tải inbox nhẹ cho badge trên top bar (không cần mở panel).
  Future<void> refreshInboxBadge() async {
    final result = await _chatRepo.getChatInbox();
    result.fold(
      (_) {},
      (raw) {
        final list = (raw['rooms'] as List?) ?? [];
        rooms = list
            .map((e) => _parseInboxRoom(Map<String, dynamic>.from(e as Map)))
            .where((r) => r.id.isNotEmpty)
            .toList();
        unreadConversations = (raw['unreadConversations'] as num?)?.toInt() ??
            rooms.where((r) => r.hasUnread).length;
        _sortRooms();
        notifyListeners();
      },
    );
  }

  ClassroomChatRoomItem _parseInboxRoom(Map<String, dynamic> m) {
    final last = m['lastMessage'];
    Map<String, dynamic>? lastMap;
    if (last is Map) lastMap = Map<String, dynamic>.from(last);

    DateTime? at;
    if (lastMap?['createdAt'] != null) {
      at = DateTime.tryParse(lastMap!['createdAt'].toString());
    }

    return ClassroomChatRoomItem(
      id: m['id']?.toString() ?? '',
      name: (m['name'] as String?)?.trim() ?? 'Lớp học',
      coverImageUrl: (m['coverImageUrl'] as String?)?.trim(),
      memberCount: (m['memberCount'] as num?)?.toInt(),
      unreadCount: (m['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessagePreview: lastMap?['preview'] as String?,
      lastSenderName: lastMap?['senderName'] as String?,
      lastMessageAt: at,
    );
  }

  void _onInboxSocket(dynamic data) {
    if (data is! Map) return;
    final d = Map<String, dynamic>.from(data);
    applyInboxSocketUpdate(d);
  }

  void applyInboxSocketUpdate(Map<String, dynamic> d) {
    final classroomId = d['classroomId']?.toString();
    if (classroomId == null || classroomId.isEmpty) return;

    final active = isActiveChat(classroomId);
    final last = d['lastMessage'];
    Map<String, dynamic>? lastMap;
    if (last is Map) lastMap = Map<String, dynamic>.from(last);

    final idx = rooms.indexWhere((r) => r.id == classroomId);
    if (idx < 0) {
      refreshInboxBadge();
      return;
    }

    var room = rooms[idx];
    if (d['coverImageUrl'] != null) {
      room = room.copyWith(coverImageUrl: d['coverImageUrl'] as String?);
    }

    if (lastMap != null) {
      room = room.copyWith(
        lastMessagePreview: lastMap['preview'] as String?,
        lastSenderName: lastMap['senderName'] as String?,
        lastMessageAt: lastMap['createdAt'] != null
            ? DateTime.tryParse(lastMap['createdAt'].toString())
            : room.lastMessageAt,
      );
    }

    if (d['markRead'] == true || active) {
      room = room.copyWith(unreadCount: 0);
    } else if (d['unreadCount'] != null) {
      room = room.copyWith(unreadCount: (d['unreadCount'] as num).toInt());
    } else if (d['unreadDelta'] != null) {
      room = room.copyWith(unreadCount: room.unreadCount + (d['unreadDelta'] as num).toInt());
    }

    final next = List<ClassroomChatRoomItem>.from(rooms);
    next[idx] = room;
    rooms = next;
    _sortRooms();
    _recalcUnreadConversations();
    notifyListeners();

    if (active && d['markRead'] != true) {
      markConversationRead(classroomId, notify: false);
    }
  }

  void _sortRooms() {
    rooms = [...rooms]..sort((a, b) {
        if (a.hasUnread != b.hasUnread) return a.hasUnread ? -1 : 1;
        final ta = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        final tb = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });
  }

  void _recalcUnreadConversations() {
    unreadConversations = rooms.where((r) => r.hasUnread).length;
  }

  Future<void> toggleListPanel() async {
    listPanelOpen = !listPanelOpen;
    if (listPanelOpen) {
      await loadRooms(force: true);
    }
    notifyListeners();
  }

  void closeListPanel() {
    if (!listPanelOpen) return;
    listPanelOpen = false;
    notifyListeners();
  }

  void openChat({required String classroomId, required String classroomName}) {
    session = ClassroomChatSession(
      classroomId: classroomId,
      classroomName: classroomName,
    );
    listPanelOpen = false;
    markConversationRead(classroomId, notify: true);
    notifyListeners();
  }

  void minimizeChat() {
    final s = session;
    if (s == null) return;
    s.minimized = true;
    notifyListeners();
  }

  void restoreChat() {
    final s = session;
    if (s == null) return;
    s.minimized = false;
    markConversationRead(s.classroomId, notify: true);
    notifyListeners();
  }

  void closeChat() {
    session = null;
    notifyListeners();
  }

  /// Đánh dấu đã đọc — cập nhật UI ngay, gọi API nền.
  Future<void> markConversationRead(String classroomId, {bool notify = true}) async {
    final idx = rooms.indexWhere((r) => r.id == classroomId);
    if (idx >= 0 && rooms[idx].unreadCount > 0) {
      final next = List<ClassroomChatRoomItem>.from(rooms);
      next[idx] = next[idx].copyWith(unreadCount: 0);
      rooms = next;
      _recalcUnreadConversations();
      if (notify) notifyListeners();
    }
    unawaited(_chatRepo.markChatRead(classroomId));
  }

  @override
  void dispose() {
    detachInboxSocket();
    super.dispose();
  }
}

void registerClassroomChatDockController() {
  if (getIt.isRegistered<ClassroomChatDockController>()) return;
  if (!getIt.isRegistered<ClassroomChatRepository>()) {
    throw StateError(
      'ClassroomChatRepository must be registered before ClassroomChatDockController',
    );
  }
  getIt.registerLazySingleton<ClassroomChatDockController>(
    () => ClassroomChatDockController(
      chatRepo: getIt<ClassroomChatRepository>(),
      socket: getIt<SocketService>(),
    ),
  );
}
