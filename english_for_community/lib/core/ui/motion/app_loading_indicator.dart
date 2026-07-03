import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import 'app_lottie_preset.dart';
import 'app_lottie_view.dart';
import 'app_motion.dart';

enum _LoadingVariant { standard, center, inline, button }

/// App-wide loading — Lottie Paperplane for page/center loads; Material spinner elsewhere.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size,
    this.strokeWidth = 2,
    this.color,
    this.forceSpinner = false,
  })  : _variant = _LoadingVariant.standard;

  /// Full-screen / page body (Lottie). ~168px on web/wide, ~112px on phone.
  const AppLoadingIndicator.center({
    super.key,
    this.color,
  })  : _variant = _LoadingVariant.center,
        size = null,
        strokeWidth = 2,
        forceSpinner = false;

  /// List footer — spinner only.
  const AppLoadingIndicator.inline({
    super.key,
    this.color,
  })  : _variant = _LoadingVariant.inline,
        size = AppMotion.loadingLottieInline,
        strokeWidth = 2,
        forceSpinner = true;

  /// Inside buttons — spinner only.
  const AppLoadingIndicator.button({
    super.key,
    this.color,
  })  : _variant = _LoadingVariant.button,
        size = AppMotion.loadingLottieButton,
        strokeWidth = 2,
        forceSpinner = true;

  final _LoadingVariant _variant;
  final double? size;
  final double strokeWidth;
  final Color? color;
  final bool forceSpinner;

  double _effectiveSize(BuildContext context) {
    switch (_variant) {
      case _LoadingVariant.center:
        return AppMotion.loadingCenterSize(context);
      case _LoadingVariant.inline:
        return AppMotion.loadingLottieInline;
      case _LoadingVariant.button:
        return AppMotion.loadingLottieButton;
      case _LoadingVariant.standard:
        return size ?? AppMotion.loadingStandardSize(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = _effectiveSize(context);
    final fallbackColor = color ?? AppColors.primary;
    final spinner = CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: fallbackColor,
    );

    final useLottie = !forceSpinner && _variant == _LoadingVariant.center;

    if (!useLottie) {
      return SizedBox(
        width: effectiveSize,
        height: effectiveSize,
        child: spinner,
      );
    }

    return AppLottieView(
      preset: AppLottiePreset.loading,
      size: effectiveSize,
      fallback: spinner,
    );
  }
}
