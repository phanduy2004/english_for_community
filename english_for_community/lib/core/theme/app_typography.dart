import 'package:flutter/material.dart';

import 'app_color.dart';

/// Typography gắn với Lexend — hierarchy rõ cho app học ngôn ngữ.
abstract final class AppTypography {
  static const String _f = 'Lexend';

  static TextStyle displaySm({Color? color}) => TextStyle(
        fontFamily: _f,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle titleMd({Color? color}) => TextStyle(
        fontFamily: _f,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle body({Color? color, FontWeight weight = FontWeight.w400}) => TextStyle(
        fontFamily: _f,
        fontSize: 15,
        height: 1.45,
        fontWeight: weight,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle label({Color? color}) => TextStyle(
        fontFamily: _f,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color ?? AppColors.textMuted,
      );
}
