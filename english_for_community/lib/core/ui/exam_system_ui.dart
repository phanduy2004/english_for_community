import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Shared visual rhythm for exam flows. **Student = mobile-first** (`03-mobile-foundations`).
abstract final class ExamSystemUi {
  static const double hPadding = 14;

  /// Khoảng cách section — compact mobile spec.
  static const double sectionGap = 20;
  static const double blockGap = 12;
  static const double cardGap = 8;
  static const double iconSm = 18;
  static const double cardRadius = AppRadius.card;

  /// Teacher web editor max width — `06-web-foundations` §4.
  static const double webTeacherContentMaxWidth = 960;

  /// Padding trang mobile (học sinh): 14 ngang.
  static EdgeInsets get pagePadding => const EdgeInsets.symmetric(horizontal: hPadding, vertical: 14);

  /// Soft elevation like SaaS list cards (no heavy stroke).
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 20, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x05000000), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static BoxDecoration softCard({double radius = cardRadius}) => BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: softCardShadow,
      );

  static TextStyle sectionTitle(BuildContext context) =>
      context.useWebTypography
          ? AppTypography.webTextTheme.labelMedium!.copyWith(color: AppColors.textPrimary)
          : AppTypography.mobileTextTheme.labelMedium!.copyWith(color: AppColors.textPrimary);

  static TextStyle listTitle(BuildContext context) => context.h3Style;

  static TextStyle questionStem(BuildContext context) => context.h3Style;

  static const TextStyle captionSecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle captionMuted = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  // --- Embedded skill panels (compact, teacher-dashboard-like) ---

  static const TextStyle embeddedCardTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.15,
    height: 1.35,
  );

  static const TextStyle embeddedSectionLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.05,
    height: 1.3,
  );

  static const TextStyle embeddedBodyStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle embeddedCaptionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.35,
  );

  static const TextStyle embeddedButtonLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.2,
  );

  static const TextStyle embeddedTabLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static TextStyle embeddedListTitle(BuildContext context) => embeddedCardTitleStyle;

  static TextStyle embeddedProgressLabel(BuildContext context) => embeddedCaptionStyle.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      );

  static PreferredSizeWidget appBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(title, style: context.h2Style),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: actions,
    );
  }
}
