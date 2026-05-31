import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

/// Teacher workspace on viewports &lt; 768px — `docs/ui-ux-system/04-mobile-components.md`.
abstract final class TeacherMobileUi {
  static const double bottomNavHeight = 60;
  static const double primaryButtonHeight = 48;
  static const double secondaryButtonHeight = 44;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s5,
    vertical: AppSpacing.s5,
  );

  static const EdgeInsets pageHeaderPadding = EdgeInsets.fromLTRB(
    AppSpacing.s5,
    AppSpacing.s5,
    AppSpacing.s5,
    AppSpacing.s3,
  );

  static bool isMobileWorkspace(BuildContext context) {
    return !WorkspaceLayoutScope.isWebWorkspace(context);
  }

  static bool isNarrowViewport(BuildContext context) {
    return MediaQuery.sizeOf(context).width < TeacherWebUi.minFallbackWidth;
  }

  static TextStyle pageTitle(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!;

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          );

  static TextStyle body(BuildContext context) => Theme.of(context).textTheme.bodyMedium!;

  static TextStyle caption(BuildContext context) => Theme.of(context).textTheme.bodySmall!.copyWith(
        color: AppColors.textSecondary,
      );

  static ButtonStyle mobileFilledStyle(BuildContext context) => FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, primaryButtonHeight),
        maximumSize: Size(double.infinity, primaryButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: AppTypography.mobileLabel,
              height: 1.0,
            ),
      );

  static ButtonStyle mobileOutlinedStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, secondaryButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.outline),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: AppTypography.mobileLabel,
            ),
      );

  static ButtonStyle mobileDangerOutlinedStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, primaryButtonHeight),
        maximumSize: Size(double.infinity, primaryButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: AppTypography.mobileLabel,
              height: 1.0,
            ),
      );

  /// Intrinsic-width row of actions (secondary toolbar).
  static ButtonStyle mobileFilledCompactStyle(BuildContext context) => FilledButton.styleFrom(
        minimumSize: const Size(0, secondaryButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  static ButtonStyle mobileOutlinedCompactStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: const Size(0, secondaryButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.outline),
      );
}
