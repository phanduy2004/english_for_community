import 'package:firebase_analytics/firebase_analytics.dart';

/// Sự kiện Free Speakding — đo trên thiết bị thật qua Firebase Analytics (DebugView / BQ export).
abstract final class SpeakingTelemetry {
  static final FirebaseAnalytics _a = FirebaseAnalytics.instance;

  static Future<void> logVapiConfigLoaded({required String source}) async {
    await _safe(() => _a.logEvent(
          name: 'free_speaking_vapi_config',
          parameters: {'source': source},
        ));
  }

  static Future<void> logCallStart() async {
    await _safe(() => _a.logEvent(name: 'free_speaking_call_start'));
  }

  static Future<void> logCallEnd() async {
    await _safe(() => _a.logEvent(name: 'free_speaking_call_end'));
  }

  static Future<void> logError(String code) async {
    await _safe(() => _a.logEvent(
          name: 'free_speaking_error',
          parameters: {'code': code},
        ));
  }

  static Future<void> logMicDenied() async {
    await _safe(() => _a.logEvent(name: 'free_speaking_mic_denied'));
  }

  static Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {}
  }
}
