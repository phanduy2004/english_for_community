import 'configure_web_url_strategy_stub.dart'
    if (dart.library.js_interop) 'configure_web_url_strategy_web.dart';

/// Enables path-based URLs on Flutter Web (`/teacher/exams` instead of `/#/teacher/exams`).
void configureWebUrlStrategy() => configureWebUrlStrategyImpl();
