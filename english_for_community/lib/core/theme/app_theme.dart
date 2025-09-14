import 'package:flutter/material.dart';
import 'app_color.dart';
import 'app_fonts.dart';

class AppTheme {
  static ThemeData getTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: Colors.redAccent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Font chung toàn app
      fontFamily: AppFonts.fontFamily,
      textTheme: const TextTheme(
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          disabledBackgroundColor: AppColors.primary.withOpacity(.3),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
