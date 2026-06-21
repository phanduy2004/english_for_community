import 'dart:async';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'classroom_chat_event.dart';
import 'classroom_chat_state.dart';
import '../classroom_chat_session_cache.dart';
import '../dock/classroom_chat_dock_controller.dart';

class ClassroomChatBloc extends Bloc<ClassroomChatEvent, ClassroomChatState> {
  final String classroomId;
  final String currentUserId;
  final ClassroomChatRepository repo;
  final SocketService socket;

  static const _uuid = Uuid();
  static const _typingTimeoutMs = 3000;
  final Map<String, Timer> _typingTimers = {};

  late void Function(dynamic) _socketMessageHandler;
  late void Function(dynamic) _socketReactHandler;
  late void Function(dynamic) _socketDeletedHandler;
  late void Function(dynamic) _socketEditedHandler;
  late void Function(dynamic) _socketTypingHandler;
  late void Function(dynamic) _socketPinnedHandler;
  late void Function(dynamic) _socketSettingsHandler;

  ClassroomChatBloc({
    required this.classroomId,
    required this.currentUserId,
    required this.repo,
    required this.socket,
    String? initialCoverImageUrl,
    String? initialGroupName,
  }) : super(_initialState(
          classroomId,
          initialCoverImageUrl: initialCoverImageUrl,
          initialGroupName: initialGroupName,
        )) {
    on<ClassroomChatLoaded>(_onLoaded);
    on<ClassroomChatLoadMore>(_onLoadMore);
    on<ClassroomChatSendText>(_onSendText);
    on<ClassroomChatSendMedia>(_onSendMedia);
    on<ClassroomChatReact>(_onReact);
    on<ClassroomChatDeleteMessage>(_onDelete);
    on<ClassroomChatEditMessage>(_onEdit);
    on<ClassroomChatMembersLoaded>(_onMembersLoaded);
    on<ClassroomChatSettingsLoaded>(_onSettingsLoaded);
    on<ClassroomChatUpdateGroupName>(_onUpdateGroupName);
    on<ClassroomChatUploadGroupAvatar>(_onUploadGroupAvatar);
    on<ClassroomChatPinMessage>(_onPinMessage);
    on<ClassroomChatUnpinMessage>(_onUnpinMessage);
    on<ClassroomChatDismissError>((_, emit) => emit(state.copyWith(clearError: true)));
    on<ClassroomChatSocketMessage>(_onSocketMessage);
    on<ClassroomChatSocketReactUpdate>(_onSocketReact);
    on<ClassroomChatSocketDeleted>(_onSocketDeleted);
    on<ClassroomChatSocketEdited>(_onSocketEdited);
    on<ClassroomChatSocketTyping>(_onSocketTyping);
    on<ClassroomChatSocketPinnedUpdated>(_onSocketPinned);
    on<ClassroomChatSocketSettingsUpdated>(_onSocketSettings);

    _setupSocket();
  }

  static ClassroomChatState _initialState(
    String classroomId, {
    String? initialCoverImageUrl,
    String? initialGroupName,
  }) {
    final cached = ClassroomChatSessionCache.peek(classroomId);
    if (cached != null && cached.messages.isNotEmpty) {
      return ClassroomChatState(
        status: ClassroomChatStatus.ready,
        messages: cached.messages,
        hasMore: cached.hasMore,
        nextCursor: cached.nextCursor,
        coverImageUrl: initialCoverImageUrl ?? cached.coverImageUrl,
        groupName: initialGroupName ?? cached.groupName,
      );
    }
    return ClassroomChatState(
      coverImageUrl: initialCoverImageUrl ?? cached?.coverImageUrl,
      groupName: initialGroupName ?? cached?.groupName,
    );
  }

  // ─── Socket setup ──────────────────────────────────────────────────────────

  void _setupSocket() {
    socket.joinClassroomChat(classroomId);

    _socketMessageHandler = (data) {
      try {
        final msg = ClassroomChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
        add(ClassroomChatSocketMessage(msg));
      } catch (e) {
        debugPrint('[Chat] socket message parse error: $e');
      }
    };
    _socketReactHandler = (data) {
      try {
        final d = Map<String, dynamic>.from(data as Map);
        final mid = d['messageId'] as String;
        final reactions = (d['reactions'] as List)
            .map((e) => ChatReaction.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        add(ClassroomChatSocketReactUpdate(messageId: mid, reactions: reactions));
      } catch (_) {}
    };
    _socketDeletedHandler = (data) {
      try {
        final mid = (data as Map)['messageId'] as String;
        add(ClassroomChatSocketDeleted(mid));
      } catch (_) {}
    };
    _socketEditedHandler = (data) {
      try {
        final msg = ClassroomChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
        add(ClassroomChatSocketEdited(msg));
      } catch (_) {}
    };
    _socketTypingHandler = (data) {
      try {
        final d = Map<String, dynamic>.from(data as Map);
        final uid = d['userId'] as String;
        final isTyping = d['isTyping'] as bool? ?? false;
        if (uid == currentUserId) return;
        add(ClassroomChatSocketTyping(userId: uid, isTyping: isTyping));
      } catch (_) {}
    };
    _socketPinnedHandler = (data) {
      try {
        final d = Map<String, dynamic>.from(data as Map);
        final raw = d['pinnedMessage'];
        ClassroomChatMessage? pinned;
        if (raw is Map) {
          pinned = ClassroomChatMessage.fromJson(Map<String, dynamic>.from(raw));
        }
        add(ClassroomChatSocketPinnedUpdated(pinnedMessage: pinned));
      } catch (_) {}
    };
    _socketSettingsHandler = (data) {
      try {
        final d = Map<String, dynamic>.from(data as Map);
        add(ClassroomChatSocketSettingsUpdated(
          name: d['name'] as String? ?? '',
          coverImageUrl: d['coverImageUrl'] as String? ?? '',
        ));
      } catch (_) {}
    };

    socket.addClassroomMessageListener(classroomId, _socketMessageHandler);
    socket.addClassroomReactListener(classroomId, _socketReactHandler);
    socket.addClassroomDeletedListener(classroomId, _socketDeletedHandler);
    socket.addClassroomEditedListener(classroomId, _socketEditedHandler);
    socket.addClassroomTypingListener(classroomId, _socketTypingHandler);
    socket.addClassroomPinnedListener(classroomId, _socketPinnedHandler);
    socket.addClassroomSettingsListener(classroomId, _socketSettingsHandler);
  }

  // ─── Load initial ──────────────────────────────────────────────────────────

  Future<void> _onLoaded(ClassroomChatLoaded event, Emitter<ClassroomChatState> emit) async {
    final cached = ClassroomChatSessionCache.peek(classroomId);
    if (state.messages.isEmpty) {
      if (cached != null && cached.messages.isNotEmpty) {
        emit(state.copyWith(
          status: ClassroomChatStatus.ready,
          messages: cached.messages,
          hasMore: cached.hasMore,
          nextCursor: cached.nextCursor,
          coverImageUrl: state.coverImageUrl ?? cached.coverImageUrl,
          groupName: state.groupName ?? cached.groupName,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(status: ClassroomChatStatus.loading));
      }
    }

    final result = await repo.getMessages(classroomId, limit: 25);
    result.fold(
      (f) {
        if (state.messages.isEmpty) {
          emit(state.copyWith(status: ClassroomChatStatus.error, errorMessage: f.message));
        } else {
          emit(state.copyWith(status: ClassroomChatStatus.ready, errorMessage: f.message));
        }
      },
      (r) {
        ClassroomChatSessionCache.put(
          classroomId: classroomId,
          messages: r.messages,
          hasMore: r.hasMore,
          nextCursor: r.nextCursor,
          coverImageUrl: state.coverImageUrl,
          groupName: state.groupName,
        );
        emit(state.copyWith(
          status: ClassroomChatStatus.ready,
          messages: r.messages,
          hasMore: r.hasMore,
          nextCursor: r.nextCursor,
          clearError: true,
        ));
        unawaited(repo.markChatRead(classroomId));
      },
    );
    add(const ClassroomChatMembersLoaded());
    add(const ClassroomChatSettingsLoaded());
  }

  Future<void> _onSettingsLoaded(
    ClassroomChatSettingsLoaded _,
    Emitter<ClassroomChatState> emit,
  ) async {
    final result = await repo.getChatSettings(classroomId);
    result.fold(
      (_) {},
      (settings) {
        ClassroomChatSessionCache.seedMeta(
          classroomId: classroomId,
          coverImageUrl: settings.coverImageUrl.isNotEmpty ? settings.coverImageUrl : null,
          groupName: settings.name,
        );
        emit(state.copyWith(
          groupName: settings.name,
          coverImageUrl: settings.coverImageUrl.isNotEmpty ? settings.coverImageUrl : null,
          pinnedMessage: settings.pinnedMessage,
          clearPinned: settings.pinnedMessage == null,
        ));
        _syncGroupCover(settings.coverImageUrl.isNotEmpty ? settings.coverImageUrl : null);
      },
    );
  }

  Future<void> _onUpdateGroupName(
    ClassroomChatUpdateGroupName event,
    Emitter<ClassroomChatState> emit,
  ) async {
    emit(state.copyWith(isUpdatingSettings: true));
    final result = await repo.updateChatSettings(classroomId, name: event.name.trim());
    result.fold(
      (f) => emit(state.copyWith(isUpdatingSettings: false, errorMessage: f.message)),
      (r) => emit(state.copyWith(
        isUpdatingSettings: false,
        groupName: r.name,
        clearError: true,
      )),
    );
  }

  Future<void> _onUploadGroupAvatar(
    ClassroomChatUploadGroupAvatar event,
    Emitter<ClassroomChatState> emit,
  ) async {
    emit(state.copyWith(isUpdatingSettings: true));
    final result = await repo.uploadChatAvatar(
      classroomId,
      filePath: event.filePath,
      bytes: event.bytes,
      fileName: event.fileName,
    );
    result.fold(
      (f) => emit(state.copyWith(isUpdatingSettings: false, errorMessage: f.message)),
      (url) {
        final cover = url.isNotEmpty ? url : null;
        _syncGroupCover(cover);
        emit(state.copyWith(
          isUpdatingSettings: false,
          coverImageUrl: cover,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onPinMessage(
    ClassroomChatPinMessage event,
    Emitter<ClassroomChatState> emit,
  ) async {
    final result = await repo.pinMessage(classroomId, event.messageId);
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (pinned) {
        if (pinned != null) {
          emit(state.copyWith(pinnedMessage: pinned, clearError: true));
        }
      },
    );
  }

  Future<void> _onUnpinMessage(
    ClassroomChatUnpinMessage _,
    Emitter<ClassroomChatState> emit,
  ) async {
    final result = await repo.unpinMessage(classroomId);
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) => emit(state.copyWith(clearPinned: true, clearError: true)),
    );
  }

  Future<void> _onMembersLoaded(ClassroomChatMembersLoaded _, Emitter<ClassroomChatState> emit) async {
    final result = await repo.getChatMembers(classroomId);
    result.fold(
      (_) {},
      (members) => emit(state.copyWith(members: members)),
    );
  }

  // ─── Load more (pagination) ────────────────────────────────────────────────

  Future<void> _onLoadMore(ClassroomChatLoadMore event, Emitter<ClassroomChatState> emit) async {
    if (!state.hasMore || state.status == ClassroomChatStatus.loadingMore) return;
    emit(state.copyWith(status: ClassroomChatStatus.loadingMore));
    final result = await repo.getMessages(classroomId, before: state.nextCursor, limit: 25);
    result.fold(
      (_) => emit(state.copyWith(status: ClassroomChatStatus.ready)),
      (r) => emit(state.copyWith(
        status: ClassroomChatStatus.ready,
        messages: [...r.messages, ...state.messages],
        hasMore: r.hasMore,
        nextCursor: r.nextCursor,
      )),
    );
  }

  // ─── Send text ─────────────────────────────────────────────────────────────

  Future<void> _onSendText(ClassroomChatSendText event, Emitter<ClassroomChatState> emit) async {
    final clientId = _uuid.v4();
    final optimistic = ClassroomChatMessage(
      id: 'pending_$clientId',
      classroomId: classroomId,
      senderId: currentUserId,
      type: ChatMessageType.text,
      content: event.content,
      replyTo: event.replyTo != null
          ? _buildReplySnapshot(event.replyTo!)
          : null,
      createdAt: DateTime.now(),
      isPending: true,
      clientId: clientId,
    );

    emit(state.copyWith(
      messages: [...state.messages, optimistic],
      isSending: true,
    ));

    final body = <String, dynamic>{
      'type': 'text',
      'content': event.content,
      'clientId': clientId,
      if (event.replyTo != null) 'replyToId': event.replyTo!.id,
      if (event.mentionIds.isNotEmpty) 'mentions': event.mentionIds,
    };

    final result = await repo.sendMessage(classroomId, body);
    result.fold(
      (f) {
        final msgs = state.messages.where((m) => m.clientId != clientId).toList();
        emit(state.copyWith(messages: msgs, isSending: false, errorMessage: f.message));
      },
      (msg) {
        final confirmed = msg.clientId == null ? msg.copyWith(clientId: clientId) : msg;
        emit(state.copyWith(
          messages: _upsertMessage(state.messages, confirmed),
          isSending: false,
          clearError: true,
        ));
      },
    );
  }

  // ─── Send media ────────────────────────────────────────────────────────────

  Future<void> _onSendMedia(ClassroomChatSendMedia event, Emitter<ClassroomChatState> emit) async {
    final clientId = _uuid.v4();
    final messageType = _mediaTypeFromMime(event.mimeType);
    final optimistic = ClassroomChatMessage(
      id: 'pending_$clientId',
      classroomId: classroomId,
      senderId: currentUserId,
      type: messageType,
      content: '',
      media: ChatMedia(
        url: '',
        name: event.fileName,
        size: event.bytes?.length ?? 0,
        mimeType: event.mimeType,
        localPreviewBytes: event.bytes,
        localPreviewPath: event.filePath,
      ),
      replyTo: event.replyTo != null ? _buildReplySnapshot(event.replyTo!) : null,
      createdAt: DateTime.now(),
      isPending: true,
      clientId: clientId,
    );

    emit(state.copyWith(
      messages: [...state.messages, optimistic],
      isUploading: true,
      clearError: true,
    ));

    final uploadResult = await repo.uploadMedia(
      classroomId,
      filePath: event.filePath,
      bytes: event.bytes,
      fileName: event.fileName,
      mimeType: event.mimeType,
    );

    await uploadResult.fold(
      (f) async {
        final msgs = state.messages.where((m) => m.clientId != clientId).toList();
        emit(state.copyWith(isUploading: false, messages: msgs, errorMessage: f.message));
      },
      (uploaded) async {
        final body = <String, dynamic>{
          'type': uploaded['messageType'] as String? ?? 'file',
          'media': uploaded['media'],
          'clientId': clientId,
          if (event.replyTo != null) 'replyToId': event.replyTo!.id,
        };

        emit(state.copyWith(isUploading: false, isSending: true));
        final sendResult = await repo.sendMessage(classroomId, body);
        sendResult.fold(
          (f) {
            final msgs = state.messages.where((m) => m.clientId != clientId).toList();
            emit(state.copyWith(isSending: false, messages: msgs, errorMessage: f.message));
          },
          (msg) {
            final confirmed = msg.clientId == null ? msg.copyWith(clientId: clientId) : msg;
            emit(state.copyWith(
              isSending: false,
              messages: _upsertMessage(state.messages, confirmed),
              clearError: true,
            ));
          },
        );
      },
    );
  }

  ChatMessageType _mediaTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) return ChatMessageType.image;
    if (mimeType.startsWith('video/')) return ChatMessageType.video;
    return ChatMessageType.file;
  }

  // ─── React ─────────────────────────────────────────────────────────────────

  Future<void> _onReact(ClassroomChatReact event, Emitter<ClassroomChatState> emit) async {
    await repo.reactMessage(classroomId, event.messageId, event.emoji);
    // Socket will emit classroom_message_react_update → handled in _onSocketReact
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDelete(ClassroomChatDeleteMessage event, Emitter<ClassroomChatState> emit) async {
    await repo.deleteMessage(classroomId, event.messageId);
    // Socket will emit classroom_message_deleted
  }

  // ─── Edit ──────────────────────────────────────────────────────────────────

  Future<void> _onEdit(ClassroomChatEditMessage event, Emitter<ClassroomChatState> emit) async {
    await repo.editMessage(classroomId, event.messageId, event.newContent);
    // Socket will emit classroom_message_edited
  }

  // ─── Socket incoming ───────────────────────────────────────────────────────

  void _syncCache(List<ClassroomChatMessage> messages) {
    ClassroomChatSessionCache.put(
      classroomId: classroomId,
      messages: messages,
      hasMore: state.hasMore,
      nextCursor: state.nextCursor,
      coverImageUrl: state.coverImageUrl,
      groupName: state.groupName,
    );
  }

  void _onSocketMessage(ClassroomChatSocketMessage event, Emitter<ClassroomChatState> emit) {
    final next = _upsertMessage(state.messages, event.message);
    emit(state.copyWith(messages: next));
    _syncCache(next);
  }

  void _onSocketReact(ClassroomChatSocketReactUpdate event, Emitter<ClassroomChatState> emit) {
    final updated = state.messages.map((m) {
      if (m.id == event.messageId) return m.copyWith(reactions: event.reactions);
      return m;
    }).toList();
    emit(state.copyWith(messages: updated));
  }

  void _onSocketDeleted(ClassroomChatSocketDeleted event, Emitter<ClassroomChatState> emit) {
    final updated = state.messages.map((m) {
      if (m.id == event.messageId) return m.copyWith(deletedAt: DateTime.now());
      return m;
    }).toList();
    final clearPin = state.pinnedMessage?.id == event.messageId;
    emit(state.copyWith(
      messages: updated,
      clearPinned: clearPin,
    ));
  }

  void _onSocketEdited(ClassroomChatSocketEdited event, Emitter<ClassroomChatState> emit) {
    final updated = state.messages.map((m) {
      if (m.id == event.message.id) return event.message;
      return m;
    }).toList();
    var pinned = state.pinnedMessage;
    if (pinned?.id == event.message.id) {
      pinned = event.message;
    }
    emit(state.copyWith(messages: updated, pinnedMessage: pinned));
  }

  void _onSocketTyping(ClassroomChatSocketTyping event, Emitter<ClassroomChatState> emit) {
    final map = Map<String, bool>.from(state.typingUsers);
    if (event.isTyping) {
      map[event.userId] = true;
      _typingTimers[event.userId]?.cancel();
      _typingTimers[event.userId] = Timer(
        const Duration(milliseconds: _typingTimeoutMs),
        () {
          if (!isClosed) add(ClassroomChatSocketTyping(userId: event.userId, isTyping: false));
        },
      );
    } else {
      map.remove(event.userId);
      _typingTimers[event.userId]?.cancel();
      _typingTimers.remove(event.userId);
    }
    emit(state.copyWith(typingUsers: map));
  }

  void _onSocketPinned(ClassroomChatSocketPinnedUpdated event, Emitter<ClassroomChatState> emit) {
    emit(state.copyWith(
      pinnedMessage: event.pinnedMessage,
      clearPinned: event.pinnedMessage == null,
    ));
  }

  void _onSocketSettings(ClassroomChatSocketSettingsUpdated event, Emitter<ClassroomChatState> emit) {
    final cover = event.coverImageUrl.isNotEmpty ? event.coverImageUrl : null;
    _syncGroupCover(cover);
    emit(state.copyWith(
      groupName: event.name,
      coverImageUrl: cover,
    ));
  }

  void _syncGroupCover(String? coverImageUrl) {
    ClassroomChatSessionCache.seedMeta(
      classroomId: classroomId,
      coverImageUrl: coverImageUrl,
      groupName: state.groupName,
    );
    if (getIt.isRegistered<ClassroomChatDockController>()) {
      getIt<ClassroomChatDockController>().updateRoomCover(classroomId, coverImageUrl);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Merge incoming message: replace pending (clientId) or existing id, else append.
  List<ClassroomChatMessage> _upsertMessage(
    List<ClassroomChatMessage> messages,
    ClassroomChatMessage incoming,
  ) {
    if (incoming.clientId != null) {
      final pendingIdx = messages.indexWhere(
        (m) => m.clientId == incoming.clientId || m.id == 'pending_${incoming.clientId}',
      );
      if (pendingIdx >= 0) {
        final next = List<ClassroomChatMessage>.from(messages);
        next[pendingIdx] = incoming.copyWith(isPending: false);
        return next;
      }
    }

    final idIdx = messages.indexWhere((m) => m.id == incoming.id);
    if (idIdx >= 0) {
      final next = List<ClassroomChatMessage>.from(messages);
      next[idIdx] = incoming.copyWith(isPending: false);
      return next;
    }

    return [...messages, incoming.copyWith(isPending: false)];
  }

  ChatReplySnapshot _buildReplySnapshot(ClassroomChatMessage m) => ChatReplySnapshot(
        messageId: m.id,
        senderId: m.senderId,
        senderName: m.sender?.fullName ?? '',
        contentPreview: m.isDeleted
            ? '[Tin nhắn đã bị xóa]'
            : m.type == ChatMessageType.text
                ? (m.content.length > 80 ? '${m.content.substring(0, 80)}…' : m.content)
                : m.media?.name ?? m.type.name,
        messageType: m.type.name,
      );

  void emitTyping(bool isTyping) {
    socket.emitClassroomTyping(classroomId, isTyping);
  }

  @override
  Future<void> close() {
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    socket.removeClassroomMessageListener(classroomId, _socketMessageHandler);
    socket.removeClassroomReactListener(classroomId, _socketReactHandler);
    socket.removeClassroomDeletedListener(classroomId, _socketDeletedHandler);
    socket.removeClassroomEditedListener(classroomId, _socketEditedHandler);
    socket.removeClassroomTypingListener(classroomId, _socketTypingHandler);
    socket.removeClassroomPinnedListener(classroomId, _socketPinnedHandler);
    socket.removeClassroomSettingsListener(classroomId, _socketSettingsHandler);
    socket.leaveClassroomChat(classroomId);
    return super.close();
  }
}
