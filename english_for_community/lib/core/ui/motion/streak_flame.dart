import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_color.dart';

/// Ngọn lửa streak — **ánh nhiệt lướt qua liên tục** (light chạy dọc ngọn lửa),
/// nhanh dần theo mốc chuỗi ngày. KHÔNG lắc/xoay tại chỗ.
///
/// Tôn trọng reduce-motion (`10-accessibility` §6): để icon tĩnh.
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.streak, this.size = 16});

  final int streak;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool hot = streak > 0;
    final Color color = streak >= 30
        ? AppColors.accentDark
        : (hot ? AppColors.accent : AppColors.textMuted);

    final Widget flame = Icon(
      Icons.local_fire_department_rounded,
      size: size,
      color: color,
    );

    if (MediaQuery.disableAnimationsOf(context)) return flame;

    // Nhiệt lướt càng nhanh khi streak càng cao.
    final int sweep = streak >= 30 ? 620 : (streak >= 7 ? 760 : 920);

    return RepaintBoundary(
      child: flame.animate(onPlay: (c) => c.repeat()).shimmer(
            duration: sweep.ms,
            color: Colors.white.withValues(alpha: hot ? 0.75 : 0.40),
          ),
    );
  }
}
