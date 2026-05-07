import 'package:dio/dio.dart';

class AppUpdateRemoteDatasource {
  final Dio dio;

  AppUpdateRemoteDatasource({required this.dio});

  Future<Map<String, dynamic>> checkVersion({
    required String platform,
    required int versionCode,
    String environment = 'production',
  }) async {
    final res = await dio.get(
      '/app/version-check',
      queryParameters: {
        'platform': platform,
        'versionCode': versionCode,
        'environment': environment,
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}
