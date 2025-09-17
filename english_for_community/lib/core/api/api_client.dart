// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_config.dart';
import 'app_jwt_interceptor.dart';

class ApiClient {
  Dio getDio({bool authorized = false}) {
    final dio = Dio(BaseOptions(baseUrl: '${ApiConfig.Base_URL}api/'));
    if (authorized) dio.interceptors.add(AppJwtInterceptor());
    dio.interceptors.add(PrettyDioLogger(
      request: true,
      requestBody: true,
      requestHeader: true,
      responseBody: true,
      responseHeader: true,
      compact: false,
    ));
    return dio;
  }
}
