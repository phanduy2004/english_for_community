part of '../socket_service.dart';

extension SocketUserHandler on SocketService {

  void userLogin(String userId) {
    if (!_isInitialized) init();

    // Lưu lại ID để dùng cho việc tự động reconnect bên file chính
    _currentUserId = userId;

    if (isConnected) {
      _socket.emit('user_login', userId);
      print('📤 [User] Emitted login: $userId');
    } else {
      _pendingUserId = userId;
      print('⏳ [User] Socket not ready, pending login for: $userId');
      if (!_socket.active) _socket.connect();
    }
  }

  void listenToForceLogout(Function(String reason) onLogout) {
    if (!_isInitialized) init();

    _socket.off('force_logout');

    _socket.on('force_logout', (data) {
      print('🚨 [Socket] Received FORCE LOGOUT: $data');
      String reason = "Phiên đăng nhập hết hạn.";
      if (data is Map && data['reason'] != null) {
        reason = data['reason'];
      }
      onLogout(reason);
    });
  }

  void disconnect() {
    if (!_isInitialized) return;

    final userId = _currentUserId;
    try {
      if (isConnected) {
        print('👋 [Socket] Sending Logout Signal for ${userId ?? 'unknown'}...');
        _socket.emit('user_logout', userId);
        _socket.disconnect();
      }
      _socket.dispose();
    } catch (e) {
      print('⚠️ Error during disconnect: $e');
    } finally {
      _isInitialized = false;
      _resetSocketSessionState();
    }
  }
}