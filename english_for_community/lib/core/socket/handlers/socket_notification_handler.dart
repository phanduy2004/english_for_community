part of '../socket_service.dart';

extension SocketNotificationHandler on SocketService {

  void listenToNotifications(Function(dynamic) onNotificationReceived) {
    if (!_isInitialized) init();

    _socket.off('new_notification');

    _socket.on('new_notification', (data) {
      // Chỉ log để debug
      print('🔔 [Socket] Raw Data: $data');

      // Chỉ truyền dữ liệu về cho UI (HomePage) xử lý
      // KHÔNG gọi LocalNotificationService ở đây nữa
      onNotificationReceived(data);
    });
  }
}