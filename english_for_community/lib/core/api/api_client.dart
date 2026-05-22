// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_config.dart';
import 'app_jwt_interceptor.dart';

class ApiClient {
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 60);
  static const Duration _sendTimeout = Duration(seconds: 60);

  static BaseOptions baseOptions({required String baseUrl}) {
    final opts = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      headers: const {'Accept': 'application/json'},
    );
    // Dio on Web cannot use sendTimeout without a request body (GET, etc.).
    if (!kIsWeb) {
      opts.sendTimeout = _sendTimeout;
    }
    return opts;
  }

  Dio getDio({bool authorized = false}) {
    final dio = Dio(baseOptions(baseUrl: '${ApiConfig.Base_URL}api/'));
    if (authorized)
      dio.interceptors.add(AppJwtInterceptor(dio: dio));
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
