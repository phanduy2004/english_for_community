import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:english_for_community/feature/student/exams/exam_session_status_banner.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_timing.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Collapsible session metadata — default **collapsed** so tabs keep maximum height.
class TeacherExamSessionCompactStrip extends StatefulWidget {
  const TeacherExamSessionCompactStrip({
    super.key,
    required this.contextData,
    required this.sessionStatus,
    this.roomCode,
    this.sessionCreatedAt,
    this.timing,
    this.initiallyExpanded = false,
  });

  final Map<String, dynamic> contextData;
  final String sessionStatus;
  final String? roomCode;
  final String? sessionCreatedAt;
  final TeacherExamSessionTimingLabels? timing;
  final bool initiallyExpanded;

  @override
  State<TeacherExamSessionCompactStrip> createState() => _TeacherExamSessionCompactStripState();
}

class _TeacherExamSessionCompactStripState extends State<TeacherExamSessionCompactStrip> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  String _statusLabel(AppLocalizations l10n) {
    return switch (widget.sessionStatus) {
      'live' => l10n.examSessionStatusLive,
      'grading' => l10n.teacherDashboardLiveStatusGrading,
      'closed' => l10n.examSessionStatusClosed,
      'canceled' => l10n.examSessionStatusCanceled,
      _ => l10n.examSessionStatusLobby,
    };
  }

  Color _statusColor() {
    return switch (widget.sessionStatus) {
      'live' => AppColors.primary,
      'grading' => AppColors.warning,
      'closed' => AppColors.textMuted,
      'canceled' => AppColors.chartTrend,
      _ => AppColors.tertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final examTitle = (widget.contextData['examTitle'] as String?)?.trim() ?? l10n.studentExamUnknownTitle;
    final className = (widget.contextData['classroomName'] as String?)?.trim() ?? '';
    final teacherName = (widget.contextData['teacherName'] as String?)?.trim() ?? '';
    final assigned = ExamAssignmentCard.formatIso(context, widget.contextData['assignedAt']);
    final room = (widget.roomCode ?? '').trim();
    final statusColor = _statusColor();

    final metaParts = <String>[];
    if (className.isNotEmpty) metaParts.add(className);
    if (widget.timing?.scheduledEnd != null) metaParts.add(widget.timing!.scheduledEnd!);
    if (room.isNotEmpty) metaParts.add('${l10n.examSessionRoomCode}: $room');
    final metaLine = metaParts.join(' · ');

    return Material(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _statusLabel(l10n),
                      style: ExamSystemUi.captionMuted.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          examTitle,
                          style: ExamSystemUi.captionSecondary.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (metaLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            metaLine,
                            style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      _expanded ? l10n.teacherExamSessionHideDetails : l10n.teacherExamSessionShowDetails,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExamSessionStatusBanner(status: widget.sessionStatus),
                  if (teacherName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(l10n.studentClassTeacher(teacherName), style: ExamSystemUi.captionMuted),
                  ],
                  if (assigned != null) ...[
                    const SizedBox(height: 4),
                    Text(l10n.examCardAssignedAt(assigned), style: ExamSystemUi.captionMuted),
                  ],
                  if (widget.sessionCreatedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(l10n.examSessionCreatedAt(widget.sessionCreatedAt!), style: ExamSystemUi.captionMuted),
                  ],
                  if (widget.timing?.started != null) ...[
                    const SizedBox(height: 4),
                    Text(l10n.examCardSessionStarted(widget.timing!.started!), style: ExamSystemUi.captionMuted),
                  ],
                  if (widget.timing?.ended != null) ...[
                    const SizedBox(height: 4),
                    Text(l10n.examCardLiveSessionEndedAt(widget.timing!.ended!), style: ExamSystemUi.captionMuted),
                  ],
                  if (widget.timing?.timeLimitBeforeStartMinutes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.examSessionTimeLimitOnStart(widget.timing!.timeLimitBeforeStartMinutes!),
                      style: ExamSystemUi.captionMuted,
                    ),
                  ] else if (widget.timing?.endsWhenTeacherEnds == true) ...[
                    const SizedBox(height: 4),
                    Text(l10n.examSessionEndsWhenTeacherEnds, style: ExamSystemUi.captionMuted),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
