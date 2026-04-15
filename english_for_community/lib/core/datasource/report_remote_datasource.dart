import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/entity/report_entity.dart';
import '../entity/admin/paginated_response.dart';

class ReportRemoteDatasource {
  final Dio dio;

  ReportRemoteDatasource({required this.dio});

  // 1. Gửi báo cáo (User) - Code cũ giữ nguyên
  Future<void> createReport(ReportEntity report) async {
    final Map<String, dynamic> mapData = {
      'type': report.type,
      'title': report.title,
      'description': report.description,
      if (report.deviceInfo != null)
        'deviceInfo': jsonEncode(report.deviceInfo!.toJson()),
    };

    final formData = FormData.fromMap(mapData);

    if (report.images != null && report.images!.isNotEmpty) {
      for (var path in report.images!) {
        if (!path.startsWith('http')) {
          final file = File(path);
          if (file.existsSync()) {
            formData.files.add(MapEntry(
              'images',
              await MultipartFile.fromFile(path),
            ));
          }
        }
      }
    }

    // Endpoint này cho User gửi báo cáo
    await dio.post('reports', data: formData);
  }

  // --- 🔥 API MỚI CHO ADMIN ---

  // 2. Lấy danh sách Report (Có lọc status + phân trang)
  Future<PaginatedResponse<ReportEntity>> getReports({
    required int page,
    required int limit,
    String? status,
    String? search,
  }) async {
    final response = await dio.get('reports', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });

    // Sử dụng factory fromJson của PaginatedResponse
    // 'data' là key chứa danh sách report trong response của Backend
    return PaginatedResponse.fromJson(
      response.data,
          (json) => ReportEntity.fromJson(json),
      dataKey: 'data',
    );
  }

  Future<ReportEntity> getReportDetail(String id) async {
    final response = await dio.get('reports/$id');
    return ReportEntity.fromJson(response.data);
  }

  Future<ReportEntity> updateReportStatus({
    required String id,
    required String status,
    String? adminResponse,
  }) async {
    final response = await dio.patch('reports/$id/status', data: {
      'status': status,
      if (adminResponse != null) 'adminResponse': adminResponse,
    });
    return ReportEntity.fromJson(response.data['report']);
  }
}