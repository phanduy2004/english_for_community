import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:flutter/material.dart';

/// Business status for a student in a realtime exam session (lobby or live).
enum TeacherExamParticipantStatus {
  notReady,
  ready,
  inProgress,
  submitted,
  expired,
  voided,
}

enum TeacherExamSessionPhase { lobby, live, ended }

/// Maps server / live-monitor payloads to [TeacherExamParticipantStatus].
class TeacherExamParticipantStatusResolver {
  const TeacherExamParticipantStatusResolver._();

  static TeacherExamParticipantStatus resolve({
    required TeacherExamSessionPhase phase,
    Map<String, dynamic>? participant,
    Map<String, dynamic>? monitorRow,
  }) {
    switch (phase) {
      case TeacherExamSessionPhase.lobby:
        return participant?['ready'] == true
            ? TeacherExamParticipantStatus.ready
            : TeacherExamParticipantStatus.notReady;
      case TeacherExamSessionPhase.live:
      case TeacherExamSessionPhase.ended:
        final status = monitorRow?['status']?.toString() ??
            participant?['attemptStatus']?.toString() ??
            participant?['status']?.toString();
        return fromAttemptStatus(status, defaultInProgress: phase == TeacherExamSessionPhase.live);
    }
  }

  static TeacherExamParticipantStatus fromAttemptStatus(
    String? status, {
    bool defaultInProgress = true,
  }) {
    switch (status) {
      case 'submitted':
        return TeacherExamParticipantStatus.submitted;
      case 'expired':
        return TeacherExamParticipantStatus.expired;
      case 'void':
        return TeacherExamParticipantStatus.voided;
      case 'in_progress':
        return TeacherExamParticipantStatus.inProgress;
      default:
        return defaultInProgress
            ? TeacherExamParticipantStatus.inProgress
            : TeacherExamParticipantStatus.submitted;
    }
  }

  static Map<String, Map<String, dynamic>> indexByUserId(
    List<Map<String, dynamic>> students,
  ) {
    final map = <String, Map<String, dynamic>>{};
    for (final s in students) {
      final id = s['userId']?.toString();
      if (id != null && id.isNotEmpty) map[id] = s;
    }
    return map;
  }
}

class TeacherExamParticipantStatusChip extends StatelessWidget {
  const TeacherExamParticipantStatusChip({
    super.key,
    required this.status,
    this.showDot = true,
  });

  final TeacherExamParticipantStatus status;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (status) {
      TeacherExamParticipantStatus.notReady => l10n.teacherExamParticipantNotReady,
      TeacherExamParticipantStatus.ready => l10n.teacherExamParticipantReady,
      TeacherExamParticipantStatus.inProgress => l10n.teacherExamParticipantInProgress,
      TeacherExamParticipantStatus.submitted => l10n.teacherExamParticipantSubmitted,
      TeacherExamParticipantStatus.expired => l10n.teacherExamParticipantExpired,
      TeacherExamParticipantStatus.voided => l10n.teacherExamParticipantVoided,
    };
    final colors = _colorsFor(status);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: ExamSystemUi.captionMuted.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _ChipColors _colorsFor(TeacherExamParticipantStatus status) {
    switch (status) {
      case TeacherExamParticipantStatus.notReady:
        return _ChipColors(
          fg: AppColors.textMuted,
          bg: AppColors.surfaceSubtle,
          border: AppColors.outlineMuted,
        );
      case TeacherExamParticipantStatus.ready:
        return _ChipColors(
          fg: AppColors.primaryDark,
          bg: AppColors.primaryTint,
          border: AppColors.primary.withValues(alpha: 0.4),
        );
      case TeacherExamParticipantStatus.inProgress:
        return _ChipColors(
          fg: AppColors.info,
          bg: AppColors.infoBg,
          border: AppColors.info.withValues(alpha: 0.35),
        );
      case TeacherExamParticipantStatus.submitted:
        return _ChipColors(
          fg: AppColors.success,
          bg: AppColors.successBg,
          border: AppColors.success.withValues(alpha: 0.35),
        );
      case TeacherExamParticipantStatus.expired:
        return _ChipColors(
          fg: AppColors.warning,
          bg: AppColors.warningBg,
          border: AppColors.warning.withValues(alpha: 0.35),
        );
      case TeacherExamParticipantStatus.voided:
        return _ChipColors(
          fg: AppColors.danger,
          bg: AppColors.dangerBg,
          border: AppColors.danger.withValues(alpha: 0.35),
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({required this.fg, required this.bg, required this.border});

  final Color fg;
  final Color bg;
  final Color border;
}
