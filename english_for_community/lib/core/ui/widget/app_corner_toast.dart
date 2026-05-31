import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';

/// Compact floating toast positioned at the bottom-right corner.
/// Replaces full-width SnackBars with a messenger-style notification.
class AppCornerToast {
  AppCornerToast._();

  static const double _horizontalPadding = 16;
  static const double _edgeInset = 20;
  static const double _minWidth = 120;
  static const double _maxWidth = 360;

  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final textStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.25,
    );
    final textDirection = Directionality.of(context);
    final painter = TextPainter(
      text: TextSpan(text: message, style: textStyle),
      textDirection: textDirection,
      maxLines: 3,
    )..layout(maxWidth: _maxWidth - _horizontalPadding * 2);

    final estimatedWidth =
        (painter.size.width + _horizontalPadding * 2).clamp(_minWidth, _maxWidth);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(message, style: textStyle),
        ),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          right: _edgeInset,
          bottom: bottomSafe + _edgeInset,
          left: screenWidth - estimatedWidth - _edgeInset,
        ),
      ),
    );
  }
}
