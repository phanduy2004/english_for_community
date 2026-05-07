import 'package:dio/dio.dart';

class AppReleaseAdminRemoteDatasource {
  final Dio dio;

  AppReleaseAdminRemoteDatasource({required this.dio});

  Future<List<Map<String, dynamic>>> getAppReleases({
    String? status,
    String? platform,
    String? environment,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await dio.get(
      'admin/app-releases',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
        if (environment != null && environment.isNotEmpty)
          'environment': environment,
      },
    );

    final list = (response.data['data'] as List<dynamic>? ?? const []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> runAction({
    required String action,
    required String releaseId,
    Map<String, dynamic>? payload,
  }) async {
    if (action == 'publish-due-run') {
      await dio.post('admin/app-releases/publish-due/run');
      return;
    }
    await dio.post(
      'admin/app-releases/$releaseId/$action',
      data: payload ?? const {},
    );
  }
}
