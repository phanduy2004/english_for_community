import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Gradebook cell / column display helpers.
class TeacherGradebookLabels {
  TeacherGradebookLabels._();

  static String studentLabel(Map<String, dynamic> row) {
    final name = (row['fullName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = (row['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email;
    return (row['username'] as String?)?.trim() ?? '—';
  }

  static String assignmentHeaderTitle(Map<String, dynamic> col) {
    return (col['examTitle'] as String?)?.trim() ?? '—';
  }

  static String assignmentHeaderSubtitle(AppLocalizations l10n, Map<String, dynamic> col) {
    return TeacherGradingHubLabels.modeLabel(l10n, col['mode'] as String?);
  }

  static String cellPrimaryText(AppLocalizations l10n, Map<String, dynamic> cell) {
    final awarded = cell['totalAwarded'];
    final max = cell['totalMax'];
    final pct = cell['scorePercent'];
    final scale = cell['scoreScale'] as String?;
    if (awarded is num && max is num && max > 0) {
      final useTen = scale == 'ten' || max == 10;
      if (useTen) {
        return awarded.toStringAsFixed(awarded % 1 == 0 ? 0 : 1);
      }
      if (pct is num) {
        return '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%';
      }
      return '${awarded.toStringAsFixed(awarded % 1 == 0 ? 0 : 1)}/${max.toStringAsFixed(max % 1 == 0 ? 0 : 1)}';
    }
    final st = cell['status'] as String? ?? 'not_started';
    if (st == 'in_progress') return '…';
    if (cell['pendingGrading'] == true) return '—';
    return '—';
  }

  static String? cellSecondaryText(AppLocalizations l10n, Map<String, dynamic> cell) {
    final awarded = cell['totalAwarded'];
    final max = cell['totalMax'];
    final pct = cell['scorePercent'];
    final scale = cell['scoreScale'] as String?;
    if (awarded is num && max is num && max > 0) {
      final useTen = scale == 'ten' || max == 10;
      if (useTen) {
        return '/ ${max.toStringAsFixed(max % 1 == 0 ? 0 : 1)}';
      }
      if (pct is num) {
        return '${awarded.toStringAsFixed(awarded % 1 == 0 ? 0 : 1)}/${max.toStringAsFixed(max % 1 == 0 ? 0 : 1)}';
      }
    }
    if (cell['pendingGrading'] == true) {
      return l10n.teacherGradebookCellPendingGrading;
    }
    final st = cell['status'] as String? ?? '';
    switch (st) {
      case 'in_progress':
        return l10n.teacherGradingStatusInProgress;
      case 'submitted':
        return l10n.teacherGradingStatusSubmitted;
      case 'not_started':
        return l10n.teacherGradebookCellNotStarted;
      default:
        return null;
    }
  }

  static TeacherStatusTone cellTone(Map<String, dynamic> cell) {
    if (cell['pendingGrading'] == true) return TeacherStatusTone.warning;
    final pct = cell['scorePercent'];
    if (pct is num) {
      if (pct >= 80) return TeacherStatusTone.success;
      if (pct >= 50) return TeacherStatusTone.primary;
      return TeacherStatusTone.danger;
    }
    final st = cell['status'] as String? ?? '';
    if (st == 'in_progress') return TeacherStatusTone.primary;
    return TeacherStatusTone.neutral;
  }

  static Color? scoreColor(Map<String, dynamic> cell) {
    final pct = cell['scorePercent'];
    if (pct is! num) return null;
    if (pct >= 80) return AppColors.success;
    if (pct >= 50) return AppColors.primaryDark;
    return AppColors.danger;
  }

  static bool cellIsTappable(Map<String, dynamic> cell) {
    final assignmentId = cell['assignmentId'] as String?;
    return assignmentId != null && assignmentId.isNotEmpty;
  }
}
