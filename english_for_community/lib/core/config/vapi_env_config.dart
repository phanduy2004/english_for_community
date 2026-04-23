/// Giá trị build-time (dev/CI) — không commit secret; dùng khi backend chưa có hoặc `--dart-define`.
abstract final class VapiEnvConfig {
  static const String publicKey = String.fromEnvironment(
    'VAPI_PUBLIC_KEY',
    defaultValue: '',
  );

  static const String assistantId = String.fromEnvironment(
    'VAPI_ASSISTANT_ID',
    defaultValue: '',
  );

  static bool get hasEnvKeys =>
      publicKey.trim().isNotEmpty && assistantId.trim().isNotEmpty;
}
