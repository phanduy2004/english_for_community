import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Web admin console tokens — `docs/ui-ux-system/06-web-foundations.md`.
abstract final class AdminWebUi {
  static const double sidebarWidth = 240;
  static const double sidebarCollapsedWidth = 56;
  static const double topBarHeight = 56;
  static const double contentMaxDashboard = 1120;
  static const double contentMaxForm = 720;
  static const double contentMaxEditor = 960;
  static const double contentMaxTable = 1280;

  static const double minFallbackWidth = 768;
  static const double sidebarExpandedMinWidth = 1024;

  /// @deprecated Dùng [minFallbackWidth].
  static const double minDesktopWidth = minFallbackWidth;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s8,
    vertical: AppSpacing.s7,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x04000000), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static BoxDecoration cardDecoration({Color? bg}) => BoxDecoration(
        color: bg ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline, width: 1),
      );

  static TextStyle webH1(BuildContext context) =>
      AppTypography.webTextTheme.headlineMedium!;

  static TextStyle webH2(BuildContext context) =>
      AppTypography.webTextTheme.titleLarge!;

  static TextStyle webH3(BuildContext context) =>
      AppTypography.webTextTheme.titleMedium!;

  static TextStyle webBody(BuildContext context) =>
      AppTypography.webTextTheme.bodyMedium!;

  static TextStyle webBodyLg(BuildContext context) =>
      AppTypography.webTextTheme.bodyLarge!;

  static TextStyle webLabel(BuildContext context) =>
      AppTypography.webTextTheme.labelMedium!;

  static TextStyle webCaption(BuildContext context) =>
      AppTypography.webTextTheme.bodySmall!;

  static TextStyle webTableHead(BuildContext context) => webLabel(context).copyWith(
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  static TextStyle webBreadcrumb(BuildContext context) => webCaption(context).copyWith(
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );
}
