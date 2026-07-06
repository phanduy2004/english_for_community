part of '../socket_service.dart';

extension SocketClassroomChatHandler on SocketService {
  // ── Join / leave ────────────────────────────────────────────────────────────

  void joinClassroomChat(String classroomId) {
    if (!_isInitialized) init();
    _joinedClassroomChatRooms.add(classroomId);
    if (!isConnected) return;
    _socket.emit('classroom_chat_join', {'classroomId': classroomId});
  }

  void leaveClassroomChat(String classroomId) {
    _joinedClassroomChatRooms.remove(classroomId);
    if (!isConnected) return;
    _socket.emit('classroom_chat_leave', {'classroomId': classroomId});
  }

  // ── Typing ──────────────────────────────────────────────────────────────────

  void emitClassroomTyping(String classroomId, bool isTyping) {
    if (!isConnected) return;
    _socket.emit('classroom_chat_typing', {
      'classroomId': classroomId,
      'isTyping': isTyping,
    });
  }

  // ── Subscribe / unsubscribe (bridge pattern — không stack `_socket.on`) ───────

  void addClassroomMessageListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatMessageCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomMessageListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatMessageCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomReactListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatReactCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomReactListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatReactCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomDeletedListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatDeletedCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomDeletedListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatDeletedCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomEditedListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatEditedCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomEditedListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatEditedCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomTypingListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatTypingCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomTypingListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatTypingCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomPinnedListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatPinnedCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomPinnedListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatPinnedCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomSettingsListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatSettingsCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomSettingsListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatSettingsCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomReadListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatReadCallbacks.putIfAbsent(classroomId, () => []).add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomReadListener(String classroomId, void Function(dynamic) handler) {
    _classroomChatReadCallbacks[classroomId]?.remove(handler);
  }

  void addClassroomInboxListener(void Function(dynamic) handler) {
    _classroomChatInboxCallbacks.add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomInboxListener(void Function(dynamic) handler) {
    _classroomChatInboxCallbacks.remove(handler);
  }

  /// "Đang nhập…" cho danh sách inbox (khác `classroom_typing` chỉ tới người
  /// đang mở phòng chat) — fanout tới mọi thành viên.
  void addClassroomInboxTypingListener(void Function(dynamic) handler) {
    _classroomChatInboxTypingCallbacks.add(handler);
    _ensureClassroomChatBridge();
  }

  void removeClassroomInboxTypingListener(void Function(dynamic) handler) {
    _classroomChatInboxTypingCallbacks.remove(handler);
  }

  void _ensureClassroomChatBridge() {
    if (!_isInitialized) init();
    if (_classroomChatBridgeAttached) return;
    _classroomChatBridgeAttached = true;

    _socket.on('classroom_message_new', (data) {
      _dispatchClassroomChat(_classroomChatMessageCallbacks, data);
    });
    _socket.on('classroom_message_react_update', (data) {
      _dispatchClassroomChat(_classroomChatReactCallbacks, data);
    });
    _socket.on('classroom_message_deleted', (data) {
      _dispatchClassroomChat(_classroomChatDeletedCallbacks, data);
    });
    _socket.on('classroom_message_edited', (data) {
      _dispatchClassroomChat(_classroomChatEditedCallbacks, data);
    });
    _socket.on('classroom_typing', (data) {
      _dispatchClassroomChat(_classroomChatTypingCallbacks, data);
    });
    _socket.on('classroom_chat_pinned_updated', (data) {
      _dispatchClassroomChat(_classroomChatPinnedCallbacks, data);
    });
    _socket.on('classroom_chat_settings_updated', (data) {
      _dispatchClassroomChat(_classroomChatSettingsCallbacks, data);
    });
    _socket.on('classroom_chat_read', (data) {
      _dispatchClassroomChat(_classroomChatReadCallbacks, data);
    });
    _socket.on('classroom_chat_inbox_updated', (data) {
      for (final cb in List<void Function(dynamic)>.from(_classroomChatInboxCallbacks)) {
        cb(data);
      }
    });
    _socket.on('classroom_chat_inbox_typing', (data) {
      for (final cb
          in List<void Function(dynamic)>.from(_classroomChatInboxTypingCallbacks)) {
        cb(data);
      }
    });
  }

  void _dispatchClassroomChat(
    Map<String, List<void Function(dynamic)>> registry,
    dynamic data,
  ) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final classroomId = map['classroomId']?.toString() ??
        (map['message'] is Map
            ? (map['message'] as Map)['classroomId']?.toString()
            : null);
    if (classroomId == null || classroomId.isEmpty) return;
    final callbacks = registry[classroomId];
    if (callbacks == null || callbacks.isEmpty) return;
    for (final cb in List<void Function(dynamic)>.from(callbacks)) {
      cb(data);
    }
  }
}
