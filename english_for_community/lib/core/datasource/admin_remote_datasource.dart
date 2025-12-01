import 'package:dio/dio.dart';
import '../entity/admin/admin_stats_entity.dart';
import '../entity/admin/paginated_response.dart';
import '../entity/report_entity.dart';
import '../entity/user_entity.dart';

class AdminRemoteDatasource {
  final Dio dio;

  AdminRemoteDatasource({required this.dio});

  // ... (Các hàm getDashboardStats, getAllUsers, getReports, updateReportStatus GIỮ NGUYÊN) ...

  Future<AdminStatsEntity> getDashboardStats({String range = 'week'}) async {
    final response = await dio.get(
      'admin/stats',
      queryParameters: {'range': range},
    );
    return AdminStatsEntity.fromJson(response.data);
  }

  Future<PaginatedResponse<UserEntity>> getAllUsers({
    int page = 1,
    int limit = 20,
    String filter = 'all',
    String? search,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
      'filter': filter,
    };
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await dio.get('admin/users', queryParameters: query);

    return PaginatedResponse.fromJson(
        response.data,
            (json) => UserEntity.fromJson(json),
        dataKey: 'users'
    );
  }

  Future<PaginatedResponse<ReportEntity>> getReports({
    int page = 1,
    int limit = 20,
    String? status
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (status != null) query['status'] = status;

    final response = await dio.get('admin/reports', queryParameters: query);

    return PaginatedResponse.fromJson(
        response.data,
            (json) => ReportEntity.fromJson(json),
        dataKey: 'reports'
    );
  }

  Future<ReportEntity> updateReportStatus({
    required String reportId,
    required String status,
    String? adminResponse,
  }) async {
    final response = await dio.patch(
      'admin/reports/$reportId',
      data: {
        'status': status,
        if (adminResponse != null) 'adminResponse': adminResponse,
      },
    );
    return ReportEntity.fromJson(response.data['report']);
  }

  // --- 🆕 HÀM GỌI API BAN USER ---
  Future<UserEntity> banUser({
    required String userId,
    required String banType,
    int? durationInHours,
    String? reason,
  }) async {
    final response = await dio.patch(
      'admin/users/$userId/ban',
      data: {
        'banType': banType,
        if (durationInHours != null) 'durationInHours': durationInHours,
        if (reason != null) 'reason': reason,
      },
    );
    // Backend trả về { message: "...", user: {...} }
    return UserEntity.fromJson(response.data['user']);
  }

  // --- 🆕 HÀM GỌI API DELETE USER ---
  Future<void> deleteUser(String userId) async {
    await dio.delete('admin/users/$userId');
  }
}