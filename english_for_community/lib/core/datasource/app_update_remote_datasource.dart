import 'package:dio/dio.dart';

class AppUpdateRemoteDatasource {
  final Dio dio;

  AppUpdateRemoteDatasource({required this.dio});

  Future<Map<String, dynamic>> checkVersion({
    required String platform,
    required int versionCode,
    String environment = 'production',
  }) async {
    // Không dùng leading '/' — với baseUrl .../api/ thì Uri.resolve('/app/...')
    // sẽ thành .../app/... (mất /api) và request sai endpoint.
    final res = await dio.get(
      'app/version-check',
      queryParameters: {
        'platform': platform,
        'versionCode': versionCode,
        'environment': environment,
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}
