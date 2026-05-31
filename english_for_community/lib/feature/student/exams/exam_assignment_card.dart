import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Rich assignment card for student + teacher classroom views (uses API `examSummary`, `schedule`, etc.).
class ExamAssignmentCard extends StatelessWidget {
  const ExamAssignmentCard({
    super.key,
    required this.assignment,
    this.isTeacherView = false,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.primaryActionEnabled = true,
  });

  final Map<String, dynamic> assignment;
  final bool isTeacherView;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final bool primaryActionEnabled;

  static String? formatIso(BuildContext context, dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
  }

  Map<String, dynamic>? _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

  String _title() {
    final summary = _map(assignment['examSummary']);
    if (summary != null) {
      final t = (summary['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    final exam = _map(assignment['examId']);
    return (exam?['title'] as String?)?.trim() ?? '';
  }

  String _description() {
    final summary = _map(assignment['examSummary']);
    final fromSummary = (summary?['description'] as String?)?.trim();
    if (fromSummary != null && fromSummary.isNotEmpty) return fromSummary;
    final exam = _map(assignment['examId']);
    return (exam?['description'] as String?)?.trim() ?? '';
  }

  String _modeLabel(AppLocalizations l10n) {
    switch (assignment['mode'] as String? ?? '') {
      case 'scheduled':
        return l10n.examModeScheduled;
      case 'realtime':
        return l10n.examModeRealtime;
      default:
        return l10n.examModeSelfPaced;
    }
  }

  String? _formatLabel(AppLocalizations l10n) {
    final fmt = _map(assignment['examSummary'])?['examFormat'] as String? ?? '';
    switch (fmt) {
      case 'integrated_four_skills':
        return l10n.examCardFormatIntegrated;
      case 'skills_exam':
        return l10n.examCardFormatSkills;
      case 'classic':
        return l10n.examCardFormatClassic;
      default:
        return fmt.isNotEmpty ? fmt : null;
    }
  }

  String? _statusHintLabel(AppLocalizations l10n) {
    if (isTeacherView) return null;
    final hint = assignment['studentStatusHint'] as String?;
    if (hint == null || hint.isEmpty) return null;
    switch (hint) {
      case 'waiting_for_teacher':
        return l10n.examWaitingForTeacher;
      case 'not_yet_open':
        return l10n.studentClassAssignmentNotYetOpen;
      case 'closed':
        return l10n.studentClassAssignmentClosed;
      case 'past_due':
        return l10n.studentExamExpired;
      case 'lobby':
        return l10n.examCardStatusLobby;
      case 'live':
        return l10n.examCardStatusLive;
      case 'session_ended':
        return l10n.examCardLiveSessionEnded;
      case 'already_submitted':
        return l10n.examCardAlreadySubmitted;
      case 'resume':
        return l10n.studentExamResumeHint;
      default:
        return null;
    }
  }

  Color _statusHintColor(String? hint) {
    switch (hint) {
      case 'session_ended':
      case 'closed':
      case 'past_due':
      case 'already_submitted':
        return AppColors.textMuted;
      case 'live':
        return AppColors.success;
      case 'lobby':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusHintIcon(String? hint) {
    switch (hint) {
      case 'session_ended':
        return Icons.event_busy_outlined;
      case 'live':
        return Icons.play_circle_outline;
      case 'lobby':
        return Icons.meeting_room_outlined;
      default:
        return Icons.info_outline;
    }
  }

  List<String> _scheduleLines(BuildContext context, AppLocalizations l10n) {
    final lines = <String>[];
    final schedule = _map(assignment['schedule']);
    final mode = assignment['mode'] as String? ?? schedule?['mode'] as String? ?? '';

    if (mode == 'self_paced') {
      final due = schedule?['dueAt'];
      final f = formatIso(context, due);
      if (f != null) lines.add(l10n.studentClassScheduleDue(f));
    } else if (mode == 'scheduled') {
      final opens = formatIso(context, schedule?['opensAt']);
      final closes = formatIso(context, schedule?['closesAt']);
      if (opens != null && closes != null) {
        lines.add(l10n.studentClassScheduleWindow(opens, closes));
      } else if (opens != null) {
        lines.add(l10n.examCardOpensAt(opens));
      } else if (closes != null) {
        lines.add(l10n.examCardClosesAt(closes));
      }
    } else if (mode == 'realtime') {
      final rsm = schedule?['realtimeScheduleMode'] as String? ??
          (schedule?['scheduledStartAt'] != null ? 'scheduled' : 'manual');
      if (rsm == 'scheduled') {
        final start = formatIso(context, schedule?['scheduledStartAt']);
        if (start != null) {
          lines.add(l10n.examCardRealtimeScheduledStart(start));
        }
        final lobby = formatIso(context, schedule?['lobbyOpensAt']);
        if (lobby != null && lobby != start) {
          lines.add(l10n.examCardRealtimeLobbyOpens(lobby));
        }
      }
    }

    final session = _map(assignment['activeSession']);
    if (mode == 'realtime' && session != null) {
      final code = (session['roomCode'] as String?)?.trim();
      if (code != null && code.isNotEmpty) {
        lines.add(l10n.examCardRoomCode(code));
      }
      final started = formatIso(context, session['startedAt']);
      if (started != null) lines.add(l10n.examCardSessionStarted(started));
    }
    final closed = _map(assignment['latestClosedSession']);
    if (mode == 'realtime' && closed != null) {
      final ended = formatIso(context, closed['endedAt'] ?? closed['createdAt']);
      if (ended != null) lines.add(l10n.examCardLiveSessionEndedAt(ended));
    }

    final assigned = formatIso(context, assignment['assignedAt']);
    if (assigned != null) lines.add(l10n.examCardAssignedAt(assigned));

    return lines;
  }

  List<String> _statsLines(AppLocalizations l10n) {
    final summary = _map(assignment['examSummary']);
    if (summary == null) return [];
    final lines = <String>[];
    final fmt = summary['examFormat'] as String? ?? '';
    final q = summary['questionCount'];
    if (q is num && q > 0) {
      lines.add(l10n.examCardQuestionsCount(q.toInt()));
    }
    final pts = summary['totalPoints'];
    if (pts is num && pts > 0) {
      lines.add(l10n.examCardPointsMax(pts.toInt()));
    }
    if (fmt == 'integrated_four_skills' || fmt == 'skills_exam') {
      final g = summary['grammarItemCount'];
      final s = summary['skillSectionCount'];
      if (g is num && (g > 0 || s is num && s > 0)) {
        lines.add(l10n.examCardGrammarSkillsCount(
          g.toInt(),
          s is num ? s.toInt() : 0,
        ));
      }
    }
    final schedule = _map(assignment['schedule']);
    final sec = schedule?['effectiveTimeLimitSeconds'] ?? summary['timeLimitSeconds'];
    if (sec is num && sec > 0) {
      final min = (sec / 60).ceil();
      lines.add(l10n.integratedExamMetaTimeLimitMinutes(min));
    }
    final desc = _formatLabel(l10n);
    if (desc != null) lines.insert(0, desc);
    return lines;
  }

  String? _myAttemptLine(AppLocalizations l10n) {
    if (isTeacherView) return null;
    final att = _map(assignment['myAttempt']);
    if (att == null) return null;
    final st = att['status'] as String? ?? '';
    if (st == 'in_progress') return l10n.examCardMyAttemptInProgress;
    if (st == 'submitted') {
      final released = att['resultsReleased'] == true;
      final awarded = att['totalAwarded'];
      final max = att['totalMax'];
      if (released && awarded is num && max is num) {
        return l10n.examCardMyAttemptScore(awarded, max);
      }
      return l10n.examCardMyAttemptSubmitted;
    }
    if (st == 'void') return l10n.examCardMyAttemptVoid;
    if (st == 'expired') return l10n.studentExamExpired;
    return null;
  }

  String? _teacherStatsLine(AppLocalizations l10n) {
    if (!isTeacherView) return null;
    final stats = _map(assignment['attemptStats']);
    if (stats == null) return null;
    final submitted = (stats['submitted'] as num?)?.toInt() ?? 0;
    final inProgress = (stats['inProgress'] as num?)?.toInt() ?? 0;
    final total = (stats['total'] as num?)?.toInt() ?? 0;
    if (total == 0) return l10n.examCardTeacherNoAttempts;
    return l10n.examCardTeacherAttemptsSummary(submitted, inProgress, total);
  }

  String? _teacherClosedSessionLine(BuildContext context, AppLocalizations l10n) {
    if (!isTeacherView) return null;
    final closed = _map(assignment['latestClosedSession']);
    if (closed == null) return null;
    final ended = formatIso(context, closed['endedAt'] ?? closed['createdAt']);
    if (ended == null) return null;
    return l10n.teacherClassHistorySessionEnded(ended);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _title();
    final displayTitle = title.isNotEmpty ? title : l10n.studentExamUnknownTitle;
    final mode = assignment['mode'] as String? ?? '';
    final hintKey = assignment['studentStatusHint'] as String?;
    final statusHint = _statusHintLabel(l10n);
    final hintColor = _statusHintColor(hintKey);
    final hintIcon = _statusHintIcon(hintKey);
    final scheduleLines = _scheduleLines(context, l10n);
    final statsLines = _statsLines(l10n);
    final attemptLine = _myAttemptLine(l10n);
    final teacherLine = _teacherStatsLine(l10n);
    final teacherClosedLine = _teacherClosedSessionLine(context, l10n);
    final desc = _description();

    return Padding(
      padding: const EdgeInsets.only(bottom: StudentMobileUi.cardGap),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 10, AppSpacing.s4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modeIconBox(mode, size: 36),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayTitle, style: StudentMobileUi.cardTitle(context)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _chip(context, _modeLabel(l10n), AppColors.primary),
                            if (assignment['status'] == 'closed')
                              _chip(context, l10n.studentClassAssignmentClosed, AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(desc, style: StudentMobileUi.body(context).copyWith(height: 1.4)),
              ],
              if (statusHint != null && statusHint.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(hintIcon, size: 16, color: hintColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusHint,
                        style: StudentMobileUi.caption(context).copyWith(
                          color: hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (scheduleLines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.examCardScheduleTitle, style: StudentMobileUi.caption(context).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...scheduleLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.schedule_outlined, size: 15, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(child: Text(line, style: StudentMobileUi.body(context))),
                      ],
                    ),
                  ),
                ),
              ],
              if (statsLines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.examCardExamInfoTitle, style: StudentMobileUi.caption(context).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: statsLines
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.outlineMuted),
                          ),
                          child: Text(s, style: StudentMobileUi.caption(context)),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (attemptLine != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(attemptLine, style: StudentMobileUi.cardTitle(context)),
                    ),
                  ],
                ),
              ],
              if (teacherClosedLine != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(teacherClosedLine, style: StudentMobileUi.caption(context))),
                  ],
                ),
              ],
              if (teacherLine != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(teacherLine, style: StudentMobileUi.body(context))),
                  ],
                ),
              ],
              if (onPrimaryAction != null && primaryActionLabel != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: primaryActionEnabled ? onPrimaryAction : null,
                    child: Text(primaryActionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeIconBox(String mode, {double size = 44}) {
    switch (mode) {
      case 'realtime':
        return StudentMobileUi.skillIconBox(
          Icons.groups_rounded,
          size: size,
          colors: SkillColorSet(
            color: AppColors.info,
            tint: AppColors.infoBg,
            dark: AppColors.info,
          ),
        );
      case 'scheduled':
        return StudentMobileUi.skillIconBox(
          Icons.event_rounded,
          size: size,
          colors: SkillColorSet(
            color: AppColors.warning,
            tint: AppColors.warningBg,
            dark: AppColors.warning,
          ),
        );
      case 'practice':
        return StudentMobileUi.skillIconBox(
          Icons.fitness_center_rounded,
          size: size,
          colors: SkillColorSet(
            color: AppSkillColors.speaking.color,
            tint: AppSkillColors.speaking.tint,
            dark: AppSkillColors.speaking.dark,
          ),
        );
      default: // self_paced
        return StudentMobileUi.skillIconBox(
          Icons.self_improvement_rounded,
          size: size,
          colors: SkillColorSet(
            color: AppSkillColors.reading.color,
            tint: AppSkillColors.reading.tint,
            dark: AppSkillColors.reading.dark,
          ),
        );
    }
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTypography.label(color: color)),
    );
  }
}
