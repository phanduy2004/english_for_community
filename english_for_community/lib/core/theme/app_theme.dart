import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color.dart';
import 'app_fonts.dart';
import 'app_typography.dart';

class AppTheme {
  /// Theme gốc: **mobile-first** (học sinh) — `docs/ui-ux-system/03-mobile-foundations.md`.
  static ThemeData getTheme() {
    final baseText = AppTypography.mobileTextTheme;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surface,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineMuted,
      shadow: Colors.black.withValues(alpha: 0.08),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: AppFonts.fontFamily,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: baseText.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: baseText.headlineMedium,
        contentTextStyle: baseText.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceInverse,
        contentTextStyle: baseText.bodyMedium?.copyWith(color: AppColors.textInverse),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 54,
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryTint,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: AppTypography.mobileLabel,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(56, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: baseText.labelLarge?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w600,
            fontSize: AppTypography.mobileLabel,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.outlineStrong,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(56, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: baseText.labelLarge?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w600,
            fontSize: AppTypography.mobileLabel,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.outlineStrong),
          minimumSize: const Size(56, 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: baseText.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: baseText.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: baseText.bodySmall,
        labelStyle: baseText.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      splashColor: AppColors.primaryStrong,
      highlightColor: AppColors.primaryTint,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(4),
        thickness: WidgetStatePropertyAll(6),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
        interactive: true,
      ),
    );
  }

  /// Typography + input/button chữ cho vùng **teacher/admin web** (ghi đè lên theme mobile).
  static ThemeData mergeWorkspaceWeb(BuildContext context) {
    final base = Theme.of(context);
    final web = AppTypography.webTextTheme;
    return base.copyWith(
      textTheme: web,
      primaryTextTheme: web,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: web.titleLarge,
        toolbarTextStyle: web.bodyMedium,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: web.headlineMedium,
        contentTextStyle: web.bodyMedium,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: web.bodySmall,
        labelStyle: web.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          textStyle: WidgetStatePropertyAll(
            web.labelMedium!.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600),
          ),
        ).merge(base.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
          textStyle: WidgetStatePropertyAll(web.bodyMedium!.copyWith(fontWeight: FontWeight.w500)),
        ).merge(base.outlinedButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
          textStyle: WidgetStatePropertyAll(
            web.labelMedium!.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600),
          ),
        ).merge(base.elevatedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(web.labelMedium!),
        ).merge(base.textButtonTheme.style),
      ),
    );
  }
}
