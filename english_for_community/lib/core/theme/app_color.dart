import 'package:flutter/material.dart';

/// Bảng màu thống nhất — học ngôn ngữ (teal/emerald + đất đá neutral).
/// Dùng chung với chart (cột chính / highlight) để không lệch tone.
abstract final class AppColors {
  /// Thương hiệu: teal học tập (khớp biểu đồ “growth”)
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF6366F1);
  static const Color tertiary = Color(0xFFF59E0B);

  static const Color surface = Color(0xFFFAFAF9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFE7E5E4);
  static const Color outlineMuted = Color(0xFFF5F5F4);

  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFF78716C);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);

  /// fl_chart / bar rods — đồng bộ với [primary]
  static const Color chartBar = primary;
  static const Color chartHighlight = Color(0xFFF59E0B);
  static const Color chartTrend = Color(0xFFEF4444);

  /// Legacy aliases (migrate dần)
  static const Color onSurface = surfaceCard;
  static const Color text = textPrimary;
}
