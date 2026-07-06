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
  late void Function(dynamic) _inboxTypingHandler;

  /// classroomId → tên người đang nhập (transient, tự xóa sau ~5s).
  final Map<String, String> _typingByRoom = {};
  final Map<String, Timer> _typingTimers = {};

  /// Cuộc trò chuyện đang mở và không thu nhỏ → không tăng unread.
  bool isActiveChat(String classroomId) {
    final s = session;
    return s != null && !s.minimized && s.classroomId == classroomId;
  }

  void attachInboxSocket() {
    if (_inboxSocketAttached) return;
    _inboxSocketAttached = true;
    _inboxHandler = _onInboxSocket;
    _inboxTypingHandler = _onInboxTyping;
    _socket.addClassroomInboxListener(_inboxHandler);
    _socket.addClassroomInboxTypingListener(_inboxTypingHandler);
  }

  void detachInboxSocket() {
    if (!_inboxSocketAttached) return;
    _socket.removeClassroomInboxListener(_inboxHandler);
    _socket.removeClassroomInboxTypingListener(_inboxTypingHandler);
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    _typingByRoom.clear();
    _inboxSocketAttached = false;
  }

  /// Tên người đang nhập trong [classroomId] (null nếu không có).
  String? typingNameFor(String classroomId) => _typingByRoom[classroomId];

  void _onInboxTyping(dynamic data) {
    if (data is! Map) return;
    final d = Map<String, dynamic>.from(data);
    final cid = d['classroomId']?.toString();
    if (cid == null || cid.isEmpty) return;
    _typingTimers.remove(cid)?.cancel();
    if (d['isTyping'] == true) {
      final name = d['userName']?.toString().trim();
      _typingByRoom[cid] = (name != null && name.isNotEmpty) ? name : 'Ai đó';
      _typingTimers[cid] = Timer(const Duration(seconds: 5), () {
        _typingByRoom.remove(cid);
        _typingTimers.remove(cid);
        notifyListeners();
      });
    } else {
      _typingByRoom.remove(cid);
    }
    notifyListeners();
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
            rooms.where((r) => r.hasUnread && !r.muted).length;
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
            rooms.where((r) => r.hasUnread && !r.muted).length;
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
      muted: m['muted'] == true,
      online: m['online'] == true,
      pinnedAt: m['pinnedAt'] != null
          ? DateTime.tryParse(m['pinnedAt'].toString())
          : null,
      lastMessagePreview: lastMap?['preview'] as String?,
      lastSenderName: lastMap?['senderName'] as String?,
      lastMessageType: lastMap?['type'] as String?,
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
        lastMessageType: lastMap['type'] as String?,
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
        // Ghim lên đầu (theo pinnedAt mới nhất), rồi tới recency.
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        if (a.isPinned && b.isPinned) {
          final pa = a.pinnedAt!.millisecondsSinceEpoch;
          final pb = b.pinnedAt!.millisecondsSinceEpoch;
          if (pa != pb) return pb.compareTo(pa);
        }
        final ta = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        final tb = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        if (ta != tb) return tb.compareTo(ta);
        if (a.hasUnread != b.hasUnread) return a.hasUnread ? -1 : 1;
        return 0;
      });
  }

  void _recalcUnreadConversations() {
    unreadConversations = rooms.where((r) => r.hasUnread && !r.muted).length;
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

  void updateRoomCover(String classroomId, String? coverImageUrl) {
    final idx = rooms.indexWhere((r) => r.id == classroomId);
    if (idx < 0) return;
    final next = List<ClassroomChatRoomItem>.from(rooms);
    next[idx] = next[idx].copyWith(coverImageUrl: coverImageUrl);
    rooms = next;
    if (session?.classroomId == classroomId) {
      session = ClassroomChatSession(
        classroomId: session!.classroomId,
        classroomName: session!.classroomName,
        coverImageUrl: coverImageUrl,
        minimized: session!.minimized,
      );
    }
    notifyListeners();
  }

  void openChat({
    required String classroomId,
    required String classroomName,
    String? coverImageUrl,
  }) {
    session = ClassroomChatSession(
      classroomId: classroomId,
      classroomName: classroomName,
      coverImageUrl: coverImageUrl,
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

  /// Unread count for a classroom inbox room (0 if not loaded yet).
  int unreadCountFor(String classroomId) {
    for (final r in rooms) {
      if (r.id == classroomId) return r.unreadCount;
    }
    return 0;
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

  /// Đánh dấu **tất cả** cuộc trò chuyện đã đọc — cập nhật UI ngay, gọi API nền.
  Future<void> markAllConversationsRead() async {
    final unreadIds =
        rooms.where((r) => r.hasUnread).map((r) => r.id).toList();
    if (unreadIds.isEmpty) return;
    rooms = [
      for (final r in rooms) r.hasUnread ? r.copyWith(unreadCount: 0) : r,
    ];
    _recalcUnreadConversations();
    notifyListeners();
    for (final id in unreadIds) {
      unawaited(_chatRepo.markChatRead(id));
    }
  }

  void _patchRoom(
    String classroomId,
    ClassroomChatRoomItem Function(ClassroomChatRoomItem) update,
  ) {
    final idx = rooms.indexWhere((r) => r.id == classroomId);
    if (idx < 0) return;
    final next = List<ClassroomChatRoomItem>.from(rooms);
    next[idx] = update(next[idx]);
    rooms = next;
  }

  /// Ghim / bỏ ghim hội thoại — cập nhật UI + sort ngay, gọi API nền.
  Future<void> togglePin(ClassroomChatRoomItem room) async {
    final pin = !room.isPinned;
    _patchRoom(
      room.id,
      (r) => pin
          ? r.copyWith(pinnedAt: DateTime.now())
          : r.copyWith(clearPinned: true),
    );
    _sortRooms();
    notifyListeners();
    unawaited(_chatRepo.setChatPinned(room.id, pin));
  }

  /// Tắt / bật thông báo hội thoại — cập nhật UI ngay, gọi API nền.
  Future<void> toggleMute(ClassroomChatRoomItem room) async {
    final mute = !room.muted;
    _patchRoom(room.id, (r) => r.copyWith(muted: mute));
    _recalcUnreadConversations();
    notifyListeners();
    unawaited(_chatRepo.setChatMuted(room.id, mute));
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
