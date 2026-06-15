import 'package:lottie/lottie.dart';

import 'app_lottie_preset.dart';

/// Parses each Lottie JSON once; reuse [LottieComposition] across rebuilds.
abstract final class AppLottieCache {
  AppLottieCache._();

  static final Map<AppLottiePreset, LottieComposition> _loaded = {};
  static Future<void>? _warmUpFuture;

  static LottieComposition? composition(AppLottiePreset preset) => _loaded[preset];

  /// Call at app start so first loading screen does not parse JSON on the UI thread.
  static Future<void> warmUp({Iterable<AppLottiePreset>? presets}) {
    return _warmUpFuture ??= _doWarmUp(presets ?? [AppLottiePreset.loading]);
  }

  static Future<void> _doWarmUp(Iterable<AppLottiePreset> presets) async {
    await Future.wait(presets.map(ensureLoaded));
  }

  static Future<LottieComposition> ensureLoaded(AppLottiePreset preset) async {
    final cached = _loaded[preset];
    if (cached != null) return cached;
    final composition = await AssetLottie(preset.assetPath).load();
    _loaded[preset] = composition;
    return composition;
  }
}
