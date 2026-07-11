import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Chuyển động "sống" cho icon — **có hướng, có di chuyển** (ánh sáng lướt qua,
/// xoay trọn vòng), KHÔNG dao động/lắc tại chỗ.
/// Tôn trọng reduce-motion (`10-accessibility` §6).
abstract final class AmbientMotion {
  /// Ánh sáng lướt ngang qua widget (gloss sweep) rồi nghỉ — light "chạy" qua.
  /// [phase] để lệch nhịp giữa nhiều icon (tạo hiệu ứng lan sóng).
  static Widget shimmer(
    BuildContext context,
    Widget child, {
    int sweepMs = 1300,
    int cycleMs = 4200,
    int phase = 0,
    Color? color,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return RepaintBoundary(
      child: child
          .animate(
            delay: (360 * phase).ms,
            onPlay: (c) => c.repeat(),
          )
          .shimmer(
            duration: sweepMs.ms,
            color: color ?? Colors.white.withValues(alpha: 0.55),
          )
          // fade 1→1 = vô hình, chỉ để kéo dài chu kỳ → có nhịp nghỉ giữa 2 lần lướt.
          .fade(begin: 1, end: 1, duration: cycleMs.ms),
    );
  }

  /// Xoay trọn 1 vòng rồi nghỉ — chuyển động xoay (không lắc qua lại).
  static Widget spin(
    BuildContext context,
    Widget child, {
    int spinMs = 850,
    int cycleMs = 3400,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return RepaintBoundary(
      child: child
          .animate(onPlay: (c) => c.repeat())
          .rotate(begin: 0, end: 1, duration: spinMs.ms, curve: Curves.easeInOut)
          .fade(begin: 1, end: 1, duration: cycleMs.ms),
    );
  }
}
