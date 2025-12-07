import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/api_config.dart';
import '../notification/local_notification_service.dart';

// Import các phần mở rộng (extensions)
part 'handlers/socket_user_handler.dart';
part 'handlers/socket_listening_handler.dart';
part 'handlers/socket_notification_handler.dart';
part 'handlers/socket_admin_handler.dart';

class SocketService {
  late IO.Socket _socket;
  bool _isInitialized = false;

  // Các biến trạng thái để xử lý Reconnect
  String? _pendingUserId;
  String? _currentUserId; // 🔥 ID user hiện tại (để reconnect)
  String? _currentListeningRoomId; // 🔥 Room bài nghe hiện tại

  /// Getter để kiểm tra socket có đang kết nối không (dùng trong các file part)
  bool get isConnected => _isInitialized && _socket.connected;

  /// Khởi tạo kết nối Socket
  void init() {
    if (_isInitialized) return;

    try {
      final url = ApiConfig.Socket_URL;
      print('🔌 [Socket] Connecting to: $url');

      _socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .enableReconnection() // Bật tự động kết nối lại
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
    });

    _socket.onDisconnect((_) => print('❌ [Socket] Disconnected'));
    _socket.onConnectError((data) => print('⚠️ [Socket] Connect Error: $data'));
    _socket.onError((data) => print('⚠️ [Socket] Error: $data'));
  }
}