part of '../socket_service.dart';

extension SocketExamHandler on SocketService {
  void setExamRealtimeContext({required String accessToken, required String sessionId}) {
    if (!_isInitialized) init();
    _examAccessToken = accessToken;
    _currentExamSessionId = sessionId;
    if (isConnected) {
      reconnectExamSocket();
    }
  }

  void clearExamRealtimeContext() {
    final sid = _currentExamSessionId;
    if (_isInitialized && isConnected && sid != null && sid.isNotEmpty) {
      _socket.emit('leave_exam_session', {'sessionId': sid});
    }
    _examAccessToken = null;
    _currentExamSessionId = null;
  }

  void listenExamSessionState(void Function(Map<String, dynamic> payload) onData) {
    if (!_isInitialized) init();
    _socket.off('exam_session_state');
    _socket.on('exam_session_state', (raw) {
      if (raw is Map) {
        onData(Map<String, dynamic>.from(raw));
      }
    });
  }

  void offExamSessionState() {
    if (_isInitialized) {
      _socket.off('exam_session_state');
    }
  }

  void listenExamSessionEnded(void Function(Map<String, dynamic> payload) onData) {
    if (!_isInitialized) init();
    _socket.off('exam_session_ended');
    _socket.on('exam_session_ended', (raw) {
      if (raw is Map) {
        onData(Map<String, dynamic>.from(raw));
      }
    });
  }

  void offExamSessionEnded() {
    if (_isInitialized) {
      _socket.off('exam_session_ended');
    }
  }

  void emitExamSessionSetReady({required String sessionId, required bool ready}) {
    if (!_isInitialized) init();
    _socket.emit('exam_session_set_ready', {'sessionId': sessionId, 'ready': ready});
  }

  /// Teacher (session leader) → live reminder that pops up on one student's screen.
  void emitTeacherExamWarnStudent({
    required String sessionId,
    required String studentUserId,
    required String message,
  }) {
    if (!_isInitialized) init();
    _socket.emit('teacher_exam_warn_student', {
      'sessionId': sessionId,
      'studentUserId': studentUserId,
      'message': message,
    });
  }

  /// Student side: teacher reminder/warning during a live exam.
  void listenExamSessionWarning(void Function(Map<String, dynamic> payload) onData) {
    if (!_isInitialized) init();
    _socket.off('exam_session_warning');
    _socket.on('exam_session_warning', (raw) {
      if (raw is Map) {
        onData(Map<String, dynamic>.from(raw));
      }
    });
  }

  void offExamSessionWarning() {
    if (_isInitialized) {
      _socket.off('exam_session_warning');
    }
  }

  void listenExamSessionKicked(void Function(Map<String, dynamic> payload) onData) {
    if (!_isInitialized) init();
    _socket.off('exam_session_kicked');
    _socket.on('exam_session_kicked', (raw) {
      if (raw is Map) {
        onData(Map<String, dynamic>.from(raw));
      }
    });
  }

  void offExamSessionKicked() {
    if (_isInitialized) {
      _socket.off('exam_session_kicked');
    }
  }

  void joinExamAssignmentProgress({required String accessToken, required String assignmentId}) {
    if (!_isInitialized) init();
    _examAccessToken = accessToken;
    if (isConnected) {
      _socket.emit('exam_register', {'accessToken': accessToken});
      _socket.emit('join_exam_assignment_progress', {'assignmentId': assignmentId});
    }
  }

  void leaveExamAssignmentProgress(String assignmentId) {
    if (!_isInitialized || !isConnected) return;
    _socket.emit('leave_exam_assignment_progress', {'assignmentId': assignmentId});
    _socket.off('exam_assignment_progress');
  }

  void listenExamAssignmentProgress(void Function(Map<String, dynamic> payload) onData) {
    if (!_isInitialized) init();
    _socket.off('exam_assignment_progress');
    _socket.on('exam_assignment_progress', (raw) {
      if (raw is Map) onData(Map<String, dynamic>.from(raw));
    });
  }

  void offExamAssignmentProgress() {
    if (_isInitialized) _socket.off('exam_assignment_progress');
  }

  void _attachExamLiveProgressBridge() {
    if (_examLiveProgressBridgeAttached) return;
    _examLiveProgressBridgeAttached = true;
    _socket.on('exam_session_live_progress', (raw) {
      if (raw is! Map) return;
      final payload = Map<String, dynamic>.from(raw);
      for (final listener in List<void Function(Map<String, dynamic>)>.from(_examLiveProgressListeners)) {
        listener(payload);
      }
    });
  }

  void _detachExamLiveProgressBridge() {
    if (!_examLiveProgressBridgeAttached) return;
    if (_examLiveProgressListeners.isNotEmpty) return;
    _socket.off('exam_session_live_progress');
    _examLiveProgressBridgeAttached = false;
  }

  void listenExamSessionLiveProgress(void Function(Map<String, dynamic> payload) onData) {
    if (!_isInitialized) init();
    if (!_examLiveProgressListeners.contains(onData)) {
      _examLiveProgressListeners.add(onData);
    }
    _attachExamLiveProgressBridge();
  }

  void offExamSessionLiveProgress([void Function(Map<String, dynamic> payload)? onData]) {
    if (onData != null) {
      _examLiveProgressListeners.remove(onData);
    } else {
      _examLiveProgressListeners.clear();
    }
    _detachExamLiveProgressBridge();
  }

  void emitExamLiveViewSync({
    required String attemptId,
    required String sessionId,
    required Map<String, dynamic> liveView,
  }) {
    if (!_isInitialized) init();
    _currentExamSessionId = sessionId;
    if (isConnected) {
      reconnectExamSocket();
    }
    _socket.emit('exam_live_view_sync', {
      'attemptId': attemptId,
      'sessionId': sessionId,
      'liveView': liveView,
    });
  }

  void _attachExamLiveScreenBridge() {
    if (_examLiveScreenBridgeAttached) return;
    _examLiveScreenBridgeAttached = true;
    _socket.on('exam_session_live_screen', (raw) {
      if (raw is! Map) return;
      final payload = Map<String, dynamic>.from(raw);
      for (final listener in List<void Function(Map<String, dynamic>)>.from(_examLiveScreenListeners)) {
        listener(payload);
      }
    });
  }

  void _detachExamLiveScreenBridge() {
    if (!_examLiveScreenBridgeAttached) return;
    if (_examLiveScreenListeners.isNotEmpty) return;
    _socket.off('exam_session_live_screen');
    _examLiveScreenBridgeAttached = false;
  }

  void listenExamSessionLiveScreen(void Function(Map<String, dynamic> payload) onData) {
    if (!_isInitialized) init();
    if (!_examLiveScreenListeners.contains(onData)) {
      _examLiveScreenListeners.add(onData);
    }
    _attachExamLiveScreenBridge();
  }

  void offExamSessionLiveScreen([void Function(Map<String, dynamic> payload)? onData]) {
    if (onData != null) {
      _examLiveScreenListeners.remove(onData);
    } else {
      _examLiveScreenListeners.clear();
    }
    _detachExamLiveScreenBridge();
  }
}
