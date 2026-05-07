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
        response.data, (json) => UserEntity.fromJson(json),
        dataKey: 'users');
  }

  Future<PaginatedResponse<ReportEntity>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (status != null) query['status'] = status;
    if (search != null && search.trim().isNotEmpty)
      query['search'] = search.trim();

    final response = await dio.get('admin/reports', queryParameters: query);

    return PaginatedResponse.fromJson(
        response.data, (json) => ReportEntity.fromJson(json),
        dataKey: 'reports');
  }

  Future<Map<String, int>> getContentSummary() async {
    final response = await dio.get('admin/content-summary');
    final raw = (response.data['data'] as Map<String, dynamic>? ?? {});
    return {
      'writing': (raw['writing'] as num?)?.toInt() ?? 0,
      'reading': (raw['reading'] as num?)?.toInt() ?? 0,
      'listening': (raw['listening'] as num?)?.toInt() ?? 0,
      'speaking': (raw['speaking'] as num?)?.toInt() ?? 0,
      'listeningDictation': (raw['listeningDictation'] as num?)?.toInt() ?? 0,
      'listeningComprehension':
          (raw['listeningComprehension'] as num?)?.toInt() ?? 0,
    };
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

  Future<PaginatedResponse<UserEntity>> getDeletedUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty)
      query['search'] = search.trim();
    final response =
        await dio.get('admin/users/deleted', queryParameters: query);
    return PaginatedResponse.fromJson(
      response.data,
      (json) => UserEntity.fromJson(json),
      dataKey: 'users',
    );
  }

  Future<UserEntity> restoreUser(String userId) async {
    final response = await dio.post('admin/users/$userId/restore');
    return UserEntity.fromJson(response.data['user']);
  }

  Future<List<Map<String, dynamic>>> getModerationQueue({
    int page = 1,
    int limit = 20,
    int slaHours = 24,
  }) async {
    final response = await dio.get(
      'admin/moderation-queue',
      queryParameters: {'page': page, 'limit': limit, 'slaHours': slaHours},
    );
    final list = (response.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getPermissionMatrix() async {
    final response = await dio.get('admin/permission-matrix');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<UserEntity> promoteUser({
    required String userId,
    required String role,
  }) async {
    final response = await dio.patch(
      'admin/users/$userId/role',
      data: {'role': role},
    );
    return UserEntity.fromJson(response.data['user']);
  }

  Future<String> exportCsvPreview({
    required String resource,
    bool onlyDeleted = false,
  }) async {
    final response = await dio.get(
      'admin/exports/csv',
      queryParameters: {
        'resource': resource,
        if (onlyDeleted) 'onlyDeleted': 'true',
      },
      options: Options(responseType: ResponseType.plain),
    );
    return (response.data ?? '').toString();
  }

  Future<void> submitWritingTopicApproval(String topicId) async {
    await dio.post('/writing/$topicId/submit-approval');
  }

  Future<void> reviewWritingTopicApproval({
    required String topicId,
    required String decision,
    String? reviewNote,
  }) async {
    await dio.post(
      '/writing/$topicId/review-approval',
      data: {
        'decision': decision,
        if (reviewNote != null) 'reviewNote': reviewNote
      },
    );
  }

  Future<List<Map<String, dynamic>>> getDeletedWritingTopics({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await dio.get(
      '/writing/admin/deleted',
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = (res.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> restoreWritingTopic(String topicId) async {
    await dio.post('/writing/$topicId/restore');
  }

  Future<List<Map<String, dynamic>>> getDeletedReadings({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await dio.get(
      '/readings/admin/deleted',
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = (res.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> restoreReading(String readingId) async {
    await dio.post('/readings/$readingId/restore');
  }

  Future<List<Map<String, dynamic>>> getDeletedListenings({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await dio.get(
      '/listenings/admin/deleted',
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = (res.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> restoreListening(String listeningId) async {
    await dio.post('/listenings/$listeningId/restore');
  }

  Future<List<Map<String, dynamic>>> getDeletedListeningComprehensions({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await dio.get(
      '/listening-comp/admin/deleted',
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = (res.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> restoreListeningComprehension(String id) async {
    await dio.post('/listening-comp/$id/restore');
  }

  Future<List<Map<String, dynamic>>> getDeletedSpeakingSets({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await dio.get(
      '/speaking/admin/deleted',
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = (res.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> restoreSpeakingSet(String id) async {
    await dio.post('/speaking/admin/$id/restore');
  }

  Future<List<Map<String, dynamic>>> getAppReleases({
    String? status,
    String? platform,
    String? environment,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await dio.get(
      'admin/app-releases',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (platform != null) 'platform': platform,
        if (environment != null) 'environment': environment,
      },
    );
    final list = (response.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> releaseAction({
    required String action,
    required String releaseId,
    Map<String, dynamic>? payload,
  }) async {
    if (action == 'publish-due-run') {
      final res = await dio.post('admin/app-releases/publish-due/run');
      return Map<String, dynamic>.from(res.data as Map);
    }

    final res = await dio.post(
      'admin/app-releases/$releaseId/$action',
      data: payload ?? const {},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
