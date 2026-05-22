import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Localized labels for attempt status / grading state in teacher grading UI.
class TeacherGradingHubLabels {
  TeacherGradingHubLabels._();

  static String? formatIso(BuildContext context, dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    return DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm().format(dt.toLocal());
  }

  static String modeLabel(AppLocalizations l10n, String? mode) {
    switch (mode ?? '') {
      case 'scheduled':
        return l10n.examModeScheduled;
      case 'realtime':
        return l10n.examModeRealtime;
      case 'practice':
        return l10n.examModePractice;
      default:
        return l10n.examModeSelfPaced;
    }
  }

  static String? examFormatLabel(AppLocalizations l10n, String? format) {
    switch (format ?? '') {
      case 'integrated_four_skills':
        return l10n.examCardFormatIntegrated;
      case 'skills_exam':
        return l10n.examCardFormatSkills;
      case 'classic':
        return l10n.examCardFormatClassic;
      default:
        final f = format?.trim() ?? '';
        return f.isNotEmpty ? f : null;
    }
  }

  static String audienceLabel(AppLocalizations l10n, String? audience) {
    if (audience == 'public') return l10n.teacherAssignmentAudiencePublic;
    return l10n.teacherAssignmentAudienceClassroom;
  }

  /// One-line meta for page subtitle (class · mode · format).
  static String assignmentContextMeta(AppLocalizations l10n, Map<String, dynamic>? assignment) {
    if (assignment == null) return '';
    final parts = <String>[];
    final className = (assignment['classroomName'] as String?)?.trim();
    if (className != null && className.isNotEmpty) parts.add(className);
    parts.add(modeLabel(l10n, assignment['mode'] as String?));
    final fmt = examFormatLabel(l10n, assignment['examFormat'] as String?);
    if (fmt != null) parts.add(fmt);
    if (assignment['audience'] == 'public') {
      parts.add(l10n.teacherAssignmentAudiencePublic);
    }
    return parts.join(' · ');
  }

  /// Schedule / window lines from assignment `config` + `mode`.
  static List<String> scheduleLines(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic>? assignment,
  ) {
    if (assignment == null) return [];
    final config = assignment['config'];
    final cfg = config is Map ? Map<String, dynamic>.from(config) : <String, dynamic>{};
    final mode = assignment['mode'] as String? ?? '';
    final lines = <String>[];

    if (mode == 'self_paced') {
      final due = formatIso(context, cfg['dueAt']);
      if (due != null) lines.add(l10n.studentClassScheduleDue(due));
    } else if (mode == 'scheduled') {
      final opens = formatIso(context, cfg['opensAt']);
      final closes = formatIso(context, cfg['closesAt']);
      if (opens != null && closes != null) {
        lines.add(l10n.studentClassScheduleWindow(opens, closes));
      } else if (opens != null) {
        lines.add(l10n.examCardOpensAt(opens));
      } else if (closes != null) {
        lines.add(l10n.examCardClosesAt(closes));
      }
    }

    final sec = cfg['timeLimitSeconds'] ?? cfg['effectiveTimeLimitSeconds'];
    if (sec is num && sec > 0) {
      final min = (sec / 60).ceil();
      lines.add(l10n.integratedExamMetaTimeLimitMinutes(min));
    }

    return lines;
  }

  static String attemptStatus(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'in_progress':
        return l10n.teacherGradingStatusInProgress;
      case 'submitted':
        return l10n.teacherGradingStatusSubmitted;
      case 'expired':
        return l10n.studentExamExpired;
      case 'void':
        return l10n.examCardMyAttemptVoid;
      default:
        return status ?? '—';
    }
  }

  static String gradingState(AppLocalizations l10n, String? state) {
    switch (state) {
      case 'pending_auto':
        return l10n.teacherGradingStatePendingAuto;
      case 'pending_ai':
        return l10n.teacherGradingStatePendingAi;
      case 'pending_manual':
        return l10n.teacherGradingStatePendingManual;
      case 'finalized':
        return l10n.teacherGradingStateFinalized;
      default:
        return state ?? '—';
    }
  }

  static String studentInitials(String label) {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
