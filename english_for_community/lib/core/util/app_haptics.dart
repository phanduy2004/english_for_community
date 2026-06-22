import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart' as theme_motion;

/// Global haptic feedback — `docs/ui-ux-system/20` §5.2.
abstract final class AppHaptics {
  AppHaptics._();

  static bool _enabled(BuildContext? context) {
    if (context == null) return true;
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// Chọn đáp án / tab / chip / lật flashcard.
  static void select([BuildContext? context]) {
    if (!_enabled(context)) return;
    HapticFeedback.selectionClick();
  }

  /// Submit / record / SRS feedback / lưu writing.
  static void confirm([BuildContext? context]) {
    if (!_enabled(context)) return;
    HapticFeedback.mediumImpact();
  }

  /// Đạt mốc streak / level / XP.
  static void celebrate([BuildContext? context]) {
    if (!_enabled(context)) return;
    HapticFeedback.heavyImpact();
  }

  /// Duration gợi ý khi pair với animation celebrate (reduce-motion aware).
  static Duration celebrateDuration(BuildContext context) {
    return theme_motion.AppMotion.effective(context, theme_motion.AppMotion.celebrate);
  }
}
