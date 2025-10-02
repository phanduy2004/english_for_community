// lib/core/api/app_jwt_interceptor.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/api/token_storage.dart';

class AppJwtInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Có thể xử lý 401 ở đây (vd. logout)
    handler.next(err);
  }
}
