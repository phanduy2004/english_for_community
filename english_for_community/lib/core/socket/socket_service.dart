import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/api_config.dart';

class SocketService {
  late IO.Socket _socket;
  bool _isInitialized = false;
  String? _pendingUserId;

  /// Khởi tạo kết nối Socket
  void init() {
    if (_isInitialized) return;

    try {
      final url = ApiConfig.Socket_URL;
      print('🔌 [Socket] Connecting to: $url');

      _socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Bắt buộc dùng WebSocket
            .disableAutoConnect()         // Tắt tự động kết nối để mình tự gọi connect()
            .enableForceNew()             // Luôn tạo session mới
            .enableReconnection()         // <--- ĐÃ SỬA LỖI: Dùng enableReconnection() thay vì setReconnection(true)
            .setReconnectionAttempts(5)   // Thử lại 5 lần nếu mất mạng
            .build(),
      );

      _socket.connect();
      _setupBaseListeners();
      _isInitialized = true;
    } catch (e) {
      print('❌ [Socket] Init Error: $e');
    }
  }

  void _setupBaseListeners() {
    _socket.onConnect((_) {
      print('✅ [Socket] Connected ID: ${_socket.id}');
      // Nếu có userId đang chờ login (do gọi userLogin trước khi connect xong), gửi ngay
      if (_pendingUserId != null) {
        print('📤 [Socket] Resending pending login for: $_pendingUserId');
        _socket.emit('user_login', _pendingUserId);
        _pendingUserId = null; // Clear sau khi gửi
      }
    });

    _socket.onDisconnect((_) => print('❌ [Socket] Disconnected'));
    _socket.onConnectError((data) => print('⚠️ [Socket] Connect Error: $data'));
    _socket.onError((data) => print('⚠️ [Socket] Error: $data'));
  }

  // ==================================================
  // CHỨC NĂNG USER
  // ==================================================

  void userLogin(String userId) {
    if (!_isInitialized) init();

    if (_socket.connected) {
      _socket.emit('user_login', userId);
      print('📤 [User] Emitted login: $userId');
    } else {
      // Lưu lại userId để gửi sau khi connect thành công (Fix lỗi race condition)
      _pendingUserId = userId;
      print('⏳ [User] Socket not ready, pending login for: $userId');

      // Đảm bảo socket đang cố kết nối
      if (!_socket.active) _socket.connect();
    }
  }

  // ==================================================
  // CHỨC NĂNG ADMIN
  // ==================================================

  void joinAdminRoom() {
    if (!_isInitialized) init();
    if (_socket.connected) {
      _socket.emit('admin_join');
    } else {
      _socket.onConnect((_) => _socket.emit('admin_join'));
    }
  }

  void listenToUserStatus(Function(dynamic) onData) {
    if (!_isInitialized) init();

    // Hủy lắng nghe cũ trước khi đăng ký mới để tránh duplicate
    _socket.off('user_status_change');

    _socket.on('user_status_change', (data) {
      print('🔔 [Admin] Status changed: $data');
      onData(data);
    });
  }
  void listenToForceLogout(Function(String reason) onLogout) {
    if (!_isInitialized) init();

    // Hủy lắng nghe cũ để tránh bị duplicate sự kiện
    _socket.off('force_logout');

    // Đăng ký lắng nghe mới
    _socket.on('force_logout', (data) {
      print('🚨 [Socket] Received FORCE LOGOUT: $data');
      String reason = "Phiên đăng nhập hết hạn.";
      if (data is Map && data['reason'] != null) {
        reason = data['reason'];
      }
      onLogout(reason);
    });
  }
  // ==================================================
  // NGẮT KẾT NỐI (LOGOUT)
  // ==================================================

  void disconnect() {
    if (_isInitialized) {
      try {
        print('👋 [Socket] Sending Logout Signal...');
        // 1. Gửi tin báo thoát chủ động để Server cập nhật Offline ngay lập tức
        _socket.emit('user_logout');

        // 2. Ngắt kết nối sau 1 chút (để tin kịp đi)
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_socket.connected) {
            print('🔌 [Socket] Disconnecting...');
            _socket.disconnect();
          }
        });
      } catch (e) {
        print('⚠️ Error during disconnect: $e');
      } finally {
        _isInitialized = false;
      }
    }
  }
}