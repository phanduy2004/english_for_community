part of '../socket_service.dart';

extension SocketAdminHandler on SocketService {

  void joinAdminRoom() {
    if (!_isInitialized) init();

    if (isConnected) {
      _socket.emit('admin_join');
    } else {
      _socket.onConnect((_) => _socket.emit('admin_join'));
    }
  }

  void listenToUserStatus(Function(dynamic) onData) {
    if (!_isInitialized) init();

    _socket.off('user_status_change');

    _socket.on('user_status_change', (data) {
      print('🔔 [Admin] Status changed: $data');
      onData(data);
    });
  }
}