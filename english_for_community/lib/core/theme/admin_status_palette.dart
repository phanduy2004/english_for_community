import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';

/// Màu pipeline / priority admin — ánh xạ về semantic `AppColors`.
/// Spec: `docs/ui-ux-system/19-admin-web-audit-and-standards.md` §5.1.
abstract final class AdminStatusPalette {
  // Pipeline release / report
  static const Color pendingBg = AppColors.warningBg;
  static const Color pendingFg = AppColors.warning;

  static const Color approvedBg = AppColors.successBg;
  static const Color approvedFg = AppColors.success;

  static const Color publishedBg = AppColors.successBg;
  static const Color publishedFg = AppColors.success;

  static const Color rejectedBg = AppColors.dangerBg;
  static const Color rejectedFg = AppColors.danger;

  static const Color scheduledBg = AppColors.infoBg;
  static const Color scheduledFg = AppColors.info;

  static const Color archivedBg = AppColors.surfaceSubtle;
  static const Color archivedFg = AppColors.textSecondary;

  // Priority / SLA (ops center)
  static const Color highBg = AppColors.dangerBg;
  static const Color highFg = AppColors.danger;

  static const Color medBg = AppColors.warningBg;
  static const Color medFg = AppColors.warning;

  static const Color lowBg = AppColors.successBg;
  static const Color lowFg = AppColors.success;

  static Color releaseStatusBg(String status) {
    switch (status) {
      case 'approved':
        return approvedBg;
      case 'published':
        return publishedBg;
      case 'pending_approval':
      case 'pending':
        return pendingBg;
      case 'scheduled':
        return scheduledBg;
      case 'rejected':
        return rejectedBg;
      case 'archived':
        return archivedBg;
      default:
        return archivedBg;
    }
  }

  static Color releaseStatusFg(String status) {
    switch (status) {
      case 'approved':
        return approvedFg;
      case 'published':
        return publishedFg;
      case 'pending_approval':
      case 'pending':
        return pendingFg;
      case 'scheduled':
        return scheduledFg;
      case 'rejected':
        return rejectedFg;
      case 'archived':
        return archivedFg;
      default:
        return archivedFg;
    }
  }

  static Color priorityBg(String level) {
    switch (level.toLowerCase()) {
      case 'high':
      case 'critical':
        return highBg;
      case 'med':
      case 'medium':
        return medBg;
      case 'low':
        return lowBg;
      default:
        return archivedBg;
    }
  }

  static Color priorityFg(String level) {
    switch (level.toLowerCase()) {
      case 'high':
      case 'critical':
        return highFg;
      case 'med':
      case 'medium':
        return medFg;
      case 'low':
        return lowFg;
      default:
        return archivedFg;
    }
  }

  /// CSV / ops table status cell — approved, rejected, pending, …
  static ({Color bg, Color fg}) csvSemanticColors(String rawValue) {
    final lower = rawValue.toLowerCase();
    if (lower == 'approved' ||
        lower == 'resolved' ||
        lower == 'active' ||
        lower == 'true' ||
        lower == 'published') {
      return (bg: approvedBg, fg: approvedFg);
    }
    if (lower == 'rejected' ||
        lower == 'banned' ||
        lower == 'deleted' ||
        lower == 'false') {
      return (bg: rejectedBg, fg: rejectedFg);
    }
    if (lower == 'pending' || lower == 'inactive' || lower == 'pending_approval') {
      return (bg: pendingBg, fg: pendingFg);
    }
    return (bg: archivedBg, fg: archivedFg);
  }
}
