import 'package:dio/dio.dart';

class AdminTeacherApplicationRemoteDatasource {
  AdminTeacherApplicationRemoteDatasource({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> list({String status = 'pending', int page = 1, int limit = 20}) async {
    final r = await dio.get(
      'admin/teacher-applications',
      queryParameters: {'status': status, 'page': page, 'limit': limit},
    );
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> approve(String applicationId) async {
    final r = await dio.post('admin/teacher-applications/$applicationId/approve');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> reject(String applicationId, String reason) async {
    final r = await dio.post(
      'admin/teacher-applications/$applicationId/reject',
      data: {'reason': reason},
    );
    return Map<String, dynamic>.from(r.data as Map);
  }
}
