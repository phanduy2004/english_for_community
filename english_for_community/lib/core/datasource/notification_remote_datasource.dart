import 'package:dio/dio.dart';

class NotificationRemoteDataSource {
  final Dio dio;

  // Endpoint prefix (Điều chỉnh nếu backend bạn khác, ví dụ 'notification' số ít hay nhiều)
  final String _endpoint = 'notifications';

  NotificationRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> getNotifications(int page) async {
    // GET /api/notifications?page=1
    final res = await dio.get('/$_endpoint', queryParameters: {'page': page});
    return res.data;
  }

  Future<void> markAsRead(String id) async {
    // PATCH /api/notifications/:id/read
    await dio.patch('/$_endpoint/$id/read');
  }

  Future<void> markAllAsRead() async {
    // PATCH /api/notifications/read-all
    await dio.patch('/$_endpoint/read-all');
  }

  Future<Map<String, dynamic>> respond(String id, String action) async {
    final res = await dio.post('/$_endpoint/$id/respond', data: {'action': action});
    return Map<String, dynamic>.from(res.data as Map);
  }
}