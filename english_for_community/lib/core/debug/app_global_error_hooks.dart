import 'dart:async';

import 'package:english_for_community/core/debug/app_dev_log.dart';
import 'package:flutter/foundation.dart';

/// Bắt Flutter framework errors + uncaught async errors → in ra terminal.
void installAppGlobalErrorHooks() {
  if (!kDebugMode && !kProfileMode) return;

  final prevFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    AppDevLog.error(
      'FlutterError',
      details.exception,
      details.stack,
    );
    prevFlutter?.call(details);
    FlutterError.presentError(details);
  };

  final prevPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    AppDevLog.error('PlatformDispatcher', error, stack);
    return prevPlatform?.call(error, stack) ?? false;
  };
}

/// Chạy [body] trong zone để bắt lỗi async không await.
Future<void> runAppWithErrorZone(Future<void> Function() body) async {
  await runZonedGuarded(
    body,
    (error, stack) => AppDevLog.error('Zone', error, stack),
  );
}
