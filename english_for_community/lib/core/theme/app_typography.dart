import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color.dart';
import 'app_fonts.dart';

/// Typography — **Inter**. Compact density v3 (`docs/ui-ux-system/00-compact-density-v3.md`).
///
/// - Body: **13**. Màn HẸP (điện thoại, kể cả web) co ~10% qua responsive
///   `textScaler` ở `main.dart` — KHÔNG bake vào hằng, để mọi text (token +
///   Material default + dialog) co đều theo bề ngang màn hình.
/// - Web page title: **16** semibold (không 18–22).
/// - KPI / số: **15** semibold + tabular figures.
abstract final class AppTypography {
  static const String _f = AppFonts.fontFamily;

  // ─── Mobile sizes (dp ≈ px) ───────────────────────────────────────────
  // Cỡ chuẩn (màn rộng). Thu nhỏ trên màn hẹp áp ở tầng app qua responsive
  // `textScaler` (xem `main.dart`), KHÔNG bake vào từng hằng.
  static const double mobileBody = 13;
  static const double mobileBodyLg = 15;
  static const double mobileH3 = 13;
  static const double mobileH2 = 14;
  static const double mobileH1 = 16;
  static const double mobileDisplay = 18;
  static const double mobileKpi = 15;
  static const double mobileCaption = 11;
  static const double mobileLabel = 11;

  /// Hero số điểm (score reveal / band lớn) — KHÔNG dùng cho body text.
  static const double mobileHero = 40;

  // ─── Web sizes ────────────────────────────────────────────────────────
  static const double webBody = 13;
  static const double webBodyLg = 15;
  static const double webH3 = 13;
  static const double webH2 = 14;
  static const double webH1 = 16;
  static const double webPageTitle = 16;
  static const double webKpi = 15;
  static const double webDisplay = 18;
  static const double webCaption = 11;
  static const double webLabel = 11;
  static const double webTable = 13;
  static const double webHero = 40;

  /// `true` chỉ trong [WorkspaceLayoutScope] (teacher/admin). Học sinh luôn mobile scale.
  static bool useWebScale(BuildContext context) {
    return WorkspaceLayoutScope.isWebWorkspace(context);
  }

  static TextTheme textThemeFor({required bool web}) => web ? webTextTheme : mobileTextTheme;

  static final TextTheme mobileTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _f,
      fontSize: mobileDisplay,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontFamily: _f,
      fontSize: mobileDisplay,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    displaySmall: TextStyle(
      fontFamily: _f,
      fontSize: mobileDisplay,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: _f,
      fontSize: mobileH1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: _f,
      fontSize: mobileH1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: _f,
      fontSize: mobileH1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: _f,
      fontSize: mobileH2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: _f,
      fontSize: mobileH3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.35,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: _f,
      fontSize: mobileH3,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: _f,
      fontSize: mobileBodyLg,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: _f,
      fontSize: mobileBody,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: _f,
      fontSize: mobileCaption,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: _f,
      fontSize: mobileBody,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.05,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: _f,
      fontSize: mobileLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: _f,
      fontSize: mobileLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
  );

  static final TextTheme webTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _f,
      fontSize: webDisplay,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontFamily: _f,
      fontSize: webDisplay,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    displaySmall: TextStyle(
      fontFamily: _f,
      fontSize: webDisplay,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: _f,
      fontSize: webPageTitle,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: _f,
      fontSize: webPageTitle,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: _f,
      fontSize: webPageTitle,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: _f,
      fontSize: webH2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: _f,
      fontSize: webH3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.35,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: _f,
      fontSize: webH3,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: _f,
      fontSize: webBodyLg,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: _f,
      fontSize: webBody,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: _f,
      fontSize: webCaption,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: _f,
      fontSize: webTable,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.05,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: _f,
      fontSize: webLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: _f,
      fontSize: webLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
  );

  // ─── Semantic helpers (prefer Theme.of(context) in widgets) ───────────

  static TextStyle displaySm({Color? color, bool web = false}) => TextStyle(
        fontFamily: _f,
        fontSize: web ? webDisplay : mobileDisplay,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle titleMd({Color? color, bool web = false}) => TextStyle(
        fontFamily: _f,
        fontSize: web ? webH2 : mobileH2,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle body({Color? color, bool web = false, bool large = false}) => TextStyle(
        fontFamily: _f,
        fontSize: web
            ? (large ? webBodyLg : webBody)
            : (large ? mobileBodyLg : mobileBody),
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle label({Color? color, bool web = false}) => TextStyle(
        fontFamily: _f,
        fontSize: web ? webLabel : mobileLabel,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle kpiValue({bool web = true}) => TextStyle(
        fontFamily: _f,
        fontSize: web ? webKpi : mobileKpi,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Số điểm hero (score reveal / band). Truyền [size] khi cần cỡ riêng.
  static TextStyle heroNumber({Color? color, bool web = false, double? size}) => TextStyle(
        fontFamily: _f,
        fontSize: size ?? (web ? webHero : mobileHero),
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Typography theo ngữ cảnh (mobile vs web/desktop).
extension AppTypographyContext on BuildContext {
  bool get useWebTypography => AppTypography.useWebScale(this);

  TextTheme get appTextTheme =>
      useWebTypography ? AppTypography.webTextTheme : AppTypography.mobileTextTheme;

  TextStyle get bodyStyle => appTextTheme.bodyMedium!;

  TextStyle get bodyLgStyle => appTextTheme.bodyLarge!;

  TextStyle get h1Style => appTextTheme.headlineMedium!;

  TextStyle get h2Style => appTextTheme.titleLarge!;

  TextStyle get h3Style => appTextTheme.titleMedium!;

  TextStyle get captionStyle => appTextTheme.bodySmall!;
}
