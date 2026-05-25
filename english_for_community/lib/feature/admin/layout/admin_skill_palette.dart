import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';

/// Màu icon kỹ năng CMS — giữ nguyên bảng màu admin hiện tại (`08-web-screens` B3).
abstract final class AdminSkillPalette {
  static const Color writing = Color(0xFFEF4444);
  static const Color speaking = Color(0xFF3B82F6);
  static const Color reading = AppColors.chartHighlight;
  static const Color listening = Color(0xFF8B5CF6);
  static const Color listeningComp = Color(0xFFA855F7);

  /// Accent cho hub / điều hướng nhanh (không phải kỹ năng).
  static const Color users = AppColors.success;
  static const Color reports = AppColors.danger;
  static const Color teacherApps = Color(0xFF0EA5E9);
  static const Color ops = Color(0xFF7C3AED);
  static const Color releases = AppColors.info;
  static const Color contentHub = AppColors.primary;
}
