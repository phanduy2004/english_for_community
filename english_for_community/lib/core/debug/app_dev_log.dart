import 'package:flutter/foundation.dart';

/// Dev-only logging — luôn in ra Debug Console / terminal `flutter run`.
abstract final class AppDevLog {
  static void info(String message) {
    if (!_enabled) return;
    debugPrint('[E4C] $message');
  }

  static void warn(String message, [Object? detail]) {
    if (!_enabled) return;
    debugPrint('[E4C][WARN] $message${detail != null ? ' | $detail' : ''}');
  }

  static void error(String tag, Object error, [StackTrace? stack]) {
    if (!_enabled) return;
    debugPrint('[E4C][ERROR][$tag] $error');
    if (stack != null) {
      debugPrint(stack.toString());
    }
  }

  static void apiError({
    required String method,
    required Uri uri,
    int? statusCode,
    Object? responseBody,
    String? message,
  }) {
    if (!_enabled) return;
    debugPrint(
      '[E4C][API] $method $uri'
      '${statusCode != null ? ' → $statusCode' : ''}'
      '${message != null ? ' | $message' : ''}'
      '${responseBody != null ? ' | body: $responseBody' : ''}',
    );
  }

  static void uiError(String message) {
    if (!_enabled) return;
    debugPrint('[E4C][UI] $message');
  }

  static bool get _enabled => kDebugMode || kProfileMode;
}
