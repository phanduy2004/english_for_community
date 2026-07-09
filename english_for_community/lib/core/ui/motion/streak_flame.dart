import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_color.dart';

/// Ngọn lửa streak "sống": nhấp nháy nhẹ, đậm dần theo mốc chuỗi ngày.
///
/// - streak 0        → xám, đứng yên.
/// - streak 1–6      → amber, pulse nhẹ.
/// - streak 7–29     → amber, pulse rõ hơn.
/// - streak ≥ 30     → amber đậm, pulse mạnh nhất.
///
/// Tôn trọng reduce-motion (`10-accessibility` §6): tắt pulse.
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.streak, this.size = 16});

  final int streak;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool active = streak > 0;
    final Color color = streak >= 30
        ? AppColors.accentDark
        : (active ? AppColors.accent : AppColors.textMuted);

    final Widget flame = Icon(
      Icons.local_fire_department_rounded,
      size: size,
      color: color,
    );

    if (!active || MediaQuery.disableAnimationsOf(context)) return flame;

    // Biên độ pulse tăng dần theo mốc.
    final double peak = streak >= 30
        ? 1.16
        : streak >= 7
            ? 1.12
            : 1.08;
    final int ms = streak >= 30 ? 780 : 950;

    return RepaintBoundary(
      child: flame
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.94, 0.94),
            end: Offset(peak, peak),
            duration: Duration(milliseconds: ms),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomCenter,
          ),
    );
  }
}
