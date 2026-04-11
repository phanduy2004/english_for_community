// feature/history/data/datasource/history_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../feature/admin/submission_managerment/model/activity_model.dart';

class HistoryRemoteDatasource {
  final Dio dio;

  HistoryRemoteDatasource({required this.dio});

  Future<List<ActivityModel>> getHistory({
    required DateTime startDate,
    required DateTime endDate,
    String? userId, // 🔥 THÊM
  }) async {
    // Format YYYY-MM-DD
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    // Tạo query params
    final Map<String, dynamic> queryParams = {
      'startDate': startStr,
      'endDate': endStr,
    };

    // Nếu có userId thì thêm vào params
    if (userId != null && userId.isNotEmpty) {
      queryParams['userId'] = userId;
    }

    final response = await dio.get(
      '/admin/activities', // Gọi đúng route đã cấu hình ở backend
      queryParameters: queryParams,
    );

    // Parse response
    final List<dynamic> data = response.data['data'];
    return data.map((json) => ActivityModel.fromJson(json)).toList();
  }

  // 🔥 ĐÃ THÊM: {String? subType}
  Future<Map<String, dynamic>> getActivityDetail(String id, String type, {String? subType}) async {
    try {
      // Đóng gói params
      final Map<String, dynamic> queryParams = {'type': type};
      if (subType != null && subType.isNotEmpty) {
        queryParams['subType'] = subType; // Gửi subType lên cho Node.js biết
      }

      final response = await dio.get(
        '/admin/activities/$id', // Thêm dấu / ở đầu cho chuẩn
        queryParameters: queryParams, // 🔥 Truyền params vào đây
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lịch sử bài tập của user đang đăng nhập (`GET /api/users/me/activities`)
  Future<ActivityHistoryListResult> getMyHistory({
    required DateTime startDate,
    required DateTime endDate,
    ActivityType? skillFilter,
    int page = 1,
    int limit = 20,
    String sort = 'desc',
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final Map<String, dynamic> queryParams = {
      'startDate': startStr,
      'endDate': endStr,
      'page': page,
      'limit': limit,
      'sort': sort,
    };

    if (skillFilter != null) {
      switch (skillFilter) {
        case ActivityType.writing:
          queryParams['type'] = 'writing';
          break;
        case ActivityType.reading:
          queryParams['type'] = 'reading';
          break;
        case ActivityType.speaking:
          queryParams['type'] = 'speaking';
          break;
        case ActivityType.listening:
          queryParams['type'] = 'listening';
          break;
        case ActivityType.unknown:
          break;
      }
    }

    final response = await dio.get(
      'users/me/activities',
      queryParameters: queryParams,
    );

    final raw = response.data;
    final List<dynamic> list = raw['data'] as List<dynamic>? ?? [];
    final items = list.map((e) => ActivityModel.fromJson(e as Map<String, dynamic>)).toList();

    return ActivityHistoryListResult(
      items: items,
      total: (raw['total'] as num?)?.toInt() ?? items.length,
      page: (raw['page'] as num?)?.toInt() ?? page,
      limit: (raw['limit'] as num?)?.toInt() ?? limit,
      hasMore: raw['hasMore'] as bool? ?? false,
    );
  }

  /// Chi tiết một bài làm của chính user (`GET /api/users/me/activities/:id`)
  Future<Map<String, dynamic>> getMyActivityDetail(String id, String type, {String? subType}) async {
    final Map<String, dynamic> queryParams = {'type': type};
    if (subType != null && subType.isNotEmpty) {
      queryParams['subType'] = subType;
    }

    final response = await dio.get(
      'users/me/activities/$id',
      queryParameters: queryParams,
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['message'] ?? 'Failed to load detail');
  }
}