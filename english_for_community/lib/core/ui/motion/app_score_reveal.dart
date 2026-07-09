import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../../theme/app_motion.dart';
import '../../util/app_haptics.dart';
import 'app_celebrate_overlay.dart';

/// Reveal điểm số ở màn kết quả: đếm số tăng dần + ăn mừng full-screen khi đạt
/// ngưỡng tốt. Dùng chung cho mọi runner (writing/speaking/reading/listening).
///
/// - [score] / [maxScore]: điểm và thang điểm (vd. 6.5 / 9, hoặc 8 / 10).
/// - [celebrateThreshold]: tỉ lệ điểm/thang để bung celebrate (mặc định 0.7).
/// - Bắn celebrate + haptic **một lần** khi widget xuất hiện (post-frame).
///
/// Tôn trọng reduce-motion (`10-accessibility` §6): hiện thẳng điểm, không celebrate.
class AppScoreReveal extends StatefulWidget {
  const AppScoreReveal({
    super.key,
    required this.score,
    required this.maxScore,
    this.fractionDigits = 1,
    this.textStyle,
    this.celebrate = true,
    this.celebrateThreshold = 0.7,
  });

  final double score;
  final double maxScore;
  final int fractionDigits;
  final TextStyle? textStyle;
  final bool celebrate;
  final double celebrateThreshold;

  @override
  State<AppScoreReveal> createState() => _AppScoreRevealState();
}

class _AppScoreRevealState extends State<AppScoreReveal> {
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    if (widget.celebrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate());
    }
  }

  void _maybeCelebrate() {
    if (_fired || !mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final double max = widget.maxScore;
    final bool good =
        max > 0 && (widget.score / max) >= widget.celebrateThreshold;
    if (!good) return;
    _fired = true;
    AppHaptics.celebrate(context);
    AppCelebrateOverlay.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = widget.textStyle ??
        const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          height: 1,
          color: AppColors.textPrimary,
        );

    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(widget.score.toStringAsFixed(widget.fractionDigits),
          style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.score),
      duration: AppMotion.effective(context, const Duration(milliseconds: 900)),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(v.toStringAsFixed(widget.fractionDigits), style: style),
    );
  }
}
