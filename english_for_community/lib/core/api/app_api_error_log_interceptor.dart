import 'package:dio/dio.dart';
import 'package:english_for_community/core/debug/app_dev_log.dart';
import 'package:flutter/foundation.dart';

/// Log chi tiết mọi API fail ra terminal (trước khi repository nuốt thành Failure).
class AppApiErrorLogInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode || kProfileMode) {
      AppDevLog.apiError(
        method: err.requestOptions.method,
        uri: err.requestOptions.uri,
        statusCode: err.response?.statusCode,
        responseBody: err.response?.data,
        message: err.message,
      );
    }
    handler.next(err);
  }
}
