import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/api_config.dart';

// Import các phần mở rộng (extensions)
part 'handlers/socket_user_handler.dart';
part 'handlers/socket_listening_handler.dart';
part 'handlers/socket_notification_handler.dart';
part 'handlers/socket_admin_handler.dart';
part 'handlers/socket_exam_handler.dart';
part 'handlers/socket_classroom_chat_handler.dart';

class SocketService {
  late IO.Socket _socket;
  bool _isInitialized = false;

  // Các biến trạng thái để xử lý Reconnect
  String? _pendingUserId;
  String? _currentUserId; // 🔥 ID user hiện tại (để reconnect)
  String? _currentListeningRoomId; // 🔥 Room bài nghe hiện tại
  String? _examAccessToken;
  String? _currentExamSessionId;
  final List<void Function(Map<String, dynamic>)> _examLiveProgressListeners = [];
  final List<void Function(Map<String, dynamic>)> _examLiveScreenListeners = [];
  bool _examLiveProgressBridgeAttached = false;
  bool _examLiveScreenBridgeAttached = false;

  // Classroom chat — one socket bridge, many per-room callbacks (tránh duplicate listeners).
  final Map<String, List<void Function(dynamic)>> _classroomChatMessageCallbacks = {};
  final Map<String, List<void Function(dynamic)>> _classroomChatReactCallbacks = {};
  final Map<String, List<void Function(dynamic)>> _classroomChatDeletedCallbacks = {};
  final Map<String, List<void Function(dynamic)>> _classroomChatEditedCallbacks = {};
  final Map<String, List<void Function(dynamic)>> _classroomChatTypingCallbacks = {};
  final Map<String, List<void Function(dynamic)>> _classroomChatPinnedCallbacks = {};
  final Map<String, List<void Function(dynamic)>> _classroomChatSettingsCallbacks = {};
  final Map<String, List<void Function(dynamic)>> _classroomChatReadCallbacks = {};
  final List<void Function(dynamic)> _classroomChatInboxCallbacks = [];
  final List<void Function(dynamic)> _classroomChatInboxTypingCallbacks = [];
  bool _classroomChatBridgeAttached = false;
  final Set<String> _joinedClassroomChatRooms = {};
  bool _pendingAdminJoin = false;

  /// Getter để kiểm tra socket có đang kết nối không (dùng trong các file part)
  bool get isConnected => _isInitialized && _socket.connected;

  /// Khởi tạo kết nối Socket
  void init() {
    if (_isInitialized) return;

    try {
      final url = ApiConfig.Socket_URL;
      print('🔌 [Socket] Connecting to: $url');

      final transports = kIsWeb ? ['websocket', 'polling'] : ['websocket', 'polling'];
      _socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(transports)
            .disableAutoConnect()
            .enableForceNew()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .build(),
      );

      _setupBaseListeners();
      _socket.connect();
      _isInitialized = true;
    } catch (e) {
      print('❌ [Socket] Init Error: $e');
    }
  }

  void _setupBaseListeners() {
    _socket.onConnect((_) {
      print('✅ [Socket] Connected ID: ${_socket.id}');

      // 1. Tự động Login lại nếu bị mất kết nối
      if (_currentUserId != null) {
        print('🔄 [Socket] Auto Re-joining User Room: $_currentUserId');
        _socket.emit('user_login', _currentUserId);
      }
      // Xử lý pending login (trường hợp gọi login trước khi connect xong)
      else if (_pendingUserId != null) {
        print('📤 [Socket] Sending pending login for: $_pendingUserId');
        _socket.emit('user_login', _pendingUserId);
        _currentUserId = _pendingUserId;
        _pendingUserId = null;
      }

      // 2. Tự động Join lại phòng bài nghe
      if (_currentListeningRoomId != null) {
        print('🔄 [Socket] Auto Re-joining Listening Room: $_currentListeningRoomId');
        _socket.emit('join_listening_room', _currentListeningRoomId);
      }

      if (_pendingAdminJoin) {
        _socket.emit('admin_join');
        _pendingAdminJoin = false;
      }

      reconnectClassroomChats();
      reconnectExamSocket();
    });

    _socket.onDisconnect((_) => print('❌ [Socket] Disconnected'));
    _socket.onConnectError((data) => print('⚠️ [Socket] Connect Error: $data'));
    _socket.onError((data) => print('⚠️ [Socket] Error: $data'));

    _socket.on('exam_session_error', (raw) {
      print('❌ [Exam socket] exam_session_error: $raw');
    });
    _socket.on('exam_register_error', (raw) {
      print('❌ [Exam socket] exam_register_error: $raw');
    });
  }

  void reconnectExamSocket() {
    if (!_isInitialized || !isConnected) return;
    if (_examAccessToken != null && _examAccessToken!.isNotEmpty) {
      _socket.emit('exam_register', {'accessToken': _examAccessToken});
    }
    if (_currentExamSessionId != null && _currentExamSessionId!.isNotEmpty) {
      _socket.emit('join_exam_session', {'sessionId': _currentExamSessionId});
    }
  }

  void reconnectClassroomChats() {
    if (!_isInitialized || !isConnected || _joinedClassroomChatRooms.isEmpty) return;
    for (final classroomId in _joinedClassroomChatRooms) {
      _socket.emit('classroom_chat_join', {'classroomId': classroomId});
    }
  }

  void _resetSocketSessionState() {
    _currentUserId = null;
    _pendingUserId = null;
    _currentListeningRoomId = null;
    _examAccessToken = null;
    _currentExamSessionId = null;
    _pendingAdminJoin = false;
    _joinedClassroomChatRooms.clear();

    _classroomChatBridgeAttached = false;
    _examLiveProgressBridgeAttached = false;
    _examLiveScreenBridgeAttached = false;

    _classroomChatMessageCallbacks.clear();
    _classroomChatReactCallbacks.clear();
    _classroomChatDeletedCallbacks.clear();
    _classroomChatEditedCallbacks.clear();
    _classroomChatTypingCallbacks.clear();
    _classroomChatPinnedCallbacks.clear();
    _classroomChatSettingsCallbacks.clear();
    _classroomChatReadCallbacks.clear();
    _classroomChatInboxCallbacks.clear();
    _classroomChatInboxTypingCallbacks.clear();
    _examLiveProgressListeners.clear();
    _examLiveScreenListeners.clear();
  }
}