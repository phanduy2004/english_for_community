import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_motion.dart';

/// Staggered fade + rise entrance cho màn student.
///
/// Dùng để "trồi" từng section của một trang khi vào màn — cùng ngôn ngữ
/// motion với [TeacherDashboardMotion.enter] nhưng dành cho student.
/// Tôn trọng reduce-motion (`10-accessibility` §6): trả child nguyên bản.
abstract final class AppEntrance {
  /// Bọc 1 section; [index] quyết định thứ tự trồi lên (stagger).
  static Widget item(
    BuildContext context,
    Widget child, {
    required int index,
    Duration? duration,
    Duration? step,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final d = duration ?? AppMotion.enter;
    final delay = (step ?? AppMotion.staggerStep) * index;
    return child
        .animate()
        .fadeIn(duration: d, delay: delay, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: d,
          delay: delay,
          curve: Curves.easeOutCubic,
        );
  }
}
