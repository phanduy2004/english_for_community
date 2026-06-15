import 'package:flutter/widgets.dart';

/// Motion tokens — "Calm Momentum" theme (120–240ms, light stagger).
abstract final class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 240);

  /// Delay between list items / stacked children when staggering in.
  static const Duration staggerStep = Duration(milliseconds: 40);

  static const double emptyLottieSize = 96;
  static const double inlineLottieSize = 48;
  static const double celebrateLottieSize = 140;

  /// Paperplane loading (`assets/animations/loading.json`).
  static const double loadingLottieCenter = 112;
  static const double loadingLottieCenterWide = 168;
  static const double loadingLottieStandard = 96;
  static const double loadingLottieStandardWide = 128;
  static const double loadingLottieInline = 40;
  static const double loadingLottieButton = 24;

  /// Web + tablet landscape / admin–teacher layout (≥600 logical px).
  static const double loadingWideBreakpoint = 600;

  static bool useWideLoading(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= loadingWideBreakpoint;
  }

  static double loadingCenterSize(BuildContext context) {
    return useWideLoading(context) ? loadingLottieCenterWide : loadingLottieCenter;
  }

  static double loadingStandardSize(BuildContext context) {
    return useWideLoading(context) ? loadingLottieStandardWide : loadingLottieStandard;
  }
}
