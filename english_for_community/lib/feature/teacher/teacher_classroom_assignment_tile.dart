import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_card_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_grading_hub_view.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Classroom assignment card — compact status pill + action menu.
class TeacherClassroomAssignmentCard extends StatelessWidget {
  const TeacherClassroomAssignmentCard({
    super.key,
    required this.assignment,
    required this.onViewAttempts,
    this.onManageSession,
    this.onClose,
    this.onDelete,
    this.compact = false,
  });

  final Map<String, dynamic> assignment;
  final VoidCallback onViewAttempts;
  final VoidCallback? onManageSession;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final bool compact;

  Map<String, dynamic>? _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

  String _title(AppLocalizations l10n) {
    final summary = _map(assignment['examSummary']);
    final fromSummary = (summary?['title'] as String?)?.trim();
    if (fromSummary != null && fromSummary.isNotEmpty) return fromSummary;
    final exam = _map(assignment['examId']);
    final fromExam = (exam?['title'] as String?)?.trim();
    if (fromExam != null && fromExam.isNotEmpty) return fromExam;
    return l10n.studentExamUnknownTitle;
  }

  String? _description() {
    final summary = _map(assignment['examSummary']);
    final fromSummary = (summary?['description'] as String?)?.trim();
    if (fromSummary != null && fromSummary.isNotEmpty) return fromSummary;
    final exam = _map(assignment['examId']);
    return (exam?['description'] as String?)?.trim();
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'realtime':
        return AppColors.success;
      case 'scheduled':
        return AppColors.warning;
      case 'practice':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  TeacherContextChipTone _modeChipTone(String mode) {
    switch (mode) {
      case 'realtime':
        return TeacherContextChipTone.live;
      case 'scheduled':
        return TeacherContextChipTone.warning;
      default:
        return TeacherContextChipTone.neutral;
    }
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'realtime':
        return Icons.sensors_outlined;
      case 'scheduled':
        return Icons.event_outlined;
      case 'practice':
        return Icons.school_outlined;
      default:
        return Icons.timer_outlined;
    }
  }

  String _statusLabel(AppLocalizations l10n, String mode) {
    if ((assignment['status'] as String?) == 'closed') {
      return l10n.studentClassAssignmentClosed;
    }
    if (mode == 'realtime') {
      final session = _map(assignment['activeSession']);
      final st = session?['status'] as String?;
      if (st == 'live') return l10n.examCardStatusLive;
      if (st == 'lobby') return l10n.examCardStatusLobby;
    }
    return TeacherGradingHubLabels.modeLabel(l10n, mode);
  }

  Color _statusColor(String mode) {
    if ((assignment['status'] as String?) == 'closed') return AppColors.textMuted;
    if (mode == 'realtime') {
      final session = _map(assignment['activeSession']);
      final st = session?['status'] as String?;
      if (st == 'live') return AppColors.success;
      if (st == 'lobby') return AppColors.primary;
    }
    return _modeColor(mode);
  }

  String? _scheduleLine(BuildContext context, AppLocalizations l10n) {
    final schedule = _map(assignment['schedule']);
    final mode = assignment['mode'] as String? ?? schedule?['mode'] as String? ?? '';
    final locale = Localizations.localeOf(context).toString();
    String? fmtDateTime(dynamic raw) {
      if (raw == null) return null;
      final dt = DateTime.tryParse(raw.toString());
      if (dt == null) return null;
      return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
    }

    if (mode == 'self_paced' || mode == 'practice') {
      final due = fmtDateTime(schedule?['dueAt']);
      if (due != null) return l10n.studentClassScheduleDue(due);
    } else if (mode == 'scheduled') {
      final opens = fmtDateTime(schedule?['opensAt']);
      final closes = fmtDateTime(schedule?['closesAt']);
      if (opens != null && closes != null) return l10n.studentClassScheduleWindow(opens, closes);
      if (opens != null) return l10n.examCardOpensAt(opens);
      if (closes != null) return l10n.examCardClosesAt(closes);
    } else if (mode == 'realtime') {
      final start = fmtDateTime(schedule?['scheduledStartAt']);
      if (start != null) return l10n.examCardRealtimeScheduledStart(start);
    }
    return null;
  }

  ({int submitted, int inProgress, int total}) _stats() {
    final stats = _map(assignment['attemptStats']);
    if (stats == null) return (submitted: 0, inProgress: 0, total: 0);
    final submitted = (stats['submitted'] as num?)?.toInt() ?? 0;
    final inProgress = (stats['inProgress'] as num?)?.toInt() ?? 0;
    final total = (stats['total'] as num?)?.toInt() ?? (submitted + inProgress);
    return (submitted: submitted, inProgress: inProgress, total: total);
  }

  int get _submittedCount => _stats().submitted;

  List<Widget> _contextChips(BuildContext context, AppLocalizations l10n, String mode) {
    final summary = _map(assignment['examSummary']);
    final chips = <Widget>[
      TeacherContextChip(
        icon: _modeIcon(mode),
        label: TeacherGradingHubLabels.modeLabel(l10n, mode),
        tone: _modeChipTone(mode),
      ),
    ];
    final formatLabel = TeacherGradingHubLabels.examFormatLabel(l10n, summary?['examFormat'] as String?);
    if (formatLabel != null) {
      chips.add(TeacherContextChip(icon: Icons.layers_outlined, label: formatLabel));
    }
    final q = summary?['questionCount'];
    if (q is num && q > 0) {
      chips.add(TeacherContextChip(icon: Icons.quiz_outlined, label: l10n.examCardQuestionsCount(q.toInt())));
    }
    final schedule = _map(assignment['schedule']);
    final sec = schedule?['effectiveTimeLimitSeconds'] ?? summary?['timeLimitSeconds'];
    if (sec is num && sec > 0) {
      final min = (sec / 60).ceil();
      chips.add(
        TeacherContextChip(
          icon: Icons.timer_outlined,
          label: l10n.integratedExamMetaTimeLimitMinutes(min),
          tone: TeacherContextChipTone.info,
        ),
      );
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final aid = assignment['id'] as String? ?? '';
    final mode = assignment['mode'] as String? ?? '';
    final isRealtime = mode == 'realtime';
    final isActive = (assignment['status'] as String?) != 'closed';
    final canDelete = _submittedCount == 0 && onDelete != null;
    final title = _title(l10n);
    final desc = _description();
    final schedule = _scheduleLine(context, l10n);
    final stats = _stats();
    final ctaLabel = isRealtime && onManageSession != null
        ? l10n.examCardManageSession
        : l10n.teacherClassOpenAttemptsList;

    return AppCard(
      variant: AppCardVariant.outline,
      child: InkWell(
        onTap: aid.isEmpty ? null : onViewAttempts,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryTint,
                    child: Text(
                      TeacherGradingHubLabels.studentInitials(title),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!compact && desc != null && desc.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: TeacherWebUi.webCaption(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            TeacherGradingPill(label: _statusLabel(l10n, mode), color: _statusColor(mode)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.submitted}',
                        style: TeacherWebUi.webKpiValue(context).copyWith(
                          color: stats.submitted > 0 ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.teacherGradingHubFilterSubmitted,
                        style: TeacherWebUi.webCaption(context),
                      ),
                    ],
                  ),
                ],
              ),
              if (schedule != null) ...[
                const SizedBox(height: AppSpacing.s4),
                TeacherGradingMetaRow(icon: Icons.schedule_outlined, text: schedule),
              ],
              if (stats.inProgress > 0 || stats.total > 0) ...[
                const SizedBox(height: AppSpacing.s2),
                TeacherGradingMetaRow(
                  icon: Icons.bar_chart_outlined,
                  text: l10n.examCardTeacherAttemptsSummary(stats.submitted, stats.inProgress, stats.total),
                ),
              ],
              const SizedBox(height: AppSpacing.s3),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _contextChips(context, l10n, mode),
              ),
              const SizedBox(height: AppSpacing.s4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onClose != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 20, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        if (v == 'close') onClose?.call();
                        if (v == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        if (isActive && onClose != null)
                          PopupMenuItem(value: 'close', child: Text(l10n.teacherAssignmentClose)),
                        if (canDelete)
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.teacherAssignmentDelete, style: const TextStyle(color: AppColors.danger)),
                          ),
                      ],
                    ),
                  FilledButton(
                    onPressed: aid.isEmpty
                        ? null
                        : () {
                            if (isRealtime && onManageSession != null) {
                              onManageSession!();
                            } else {
                              onViewAttempts();
                            }
                          },
                    style: TeacherWebUi.compactFilledStyle(context),
                    child: Text(ctaLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Classroom assignment row wrapper with spacing.
class TeacherClassroomAssignmentTile extends StatelessWidget {
  const TeacherClassroomAssignmentTile({
    super.key,
    required this.assignment,
    required this.onViewAttempts,
    this.onManageSession,
    this.onClose,
    this.onDelete,
    this.compact = false,
  });

  final Map<String, dynamic> assignment;
  final VoidCallback onViewAttempts;
  final VoidCallback? onManageSession;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: TeacherClassroomAssignmentCard(
        assignment: assignment,
        onViewAttempts: onViewAttempts,
        onManageSession: onManageSession,
        onClose: onClose,
        onDelete: onDelete,
        compact: compact,
      ),
    );
  }

  /// Full-height bottom sheet with student attempt list for this assignment.
  static Future<void> showAttemptsSheet(
    BuildContext context, {
    required String assignmentId,
    String? examTitleHint,
  }) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineMuted,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.teacherClassViewStudentAttempts,
                          style: ExamSystemUi.sectionTitle(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TeacherAssignmentGradingHubView(
                    assignmentId: assignmentId,
                    scrollController: scrollController,
                    examTitleHint: examTitleHint,
                    padding: ExamSystemUi.pagePadding.copyWith(top: 0),
                    showPageHeader: false,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
