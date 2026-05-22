import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:english_for_community/feature/student/exams/exam_session_status_banner.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_timing.dart';
import 'package:flutter/material.dart';

/// Class + exam + teacher metadata for the live session console.
class TeacherExamSessionContextCard extends StatelessWidget {
  const TeacherExamSessionContextCard({
    super.key,
    required this.contextData,
    required this.sessionStatus,
    this.roomCode,
    this.sessionCreatedAt,
    this.timing,
  });

  final Map<String, dynamic> contextData;
  final String sessionStatus;
  final String? roomCode;
  final String? sessionCreatedAt;
  final TeacherExamSessionTimingLabels? timing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final examTitle = (contextData['examTitle'] as String?)?.trim() ?? l10n.studentExamUnknownTitle;
    final className = (contextData['classroomName'] as String?)?.trim() ?? '';
    final teacherName = (contextData['teacherName'] as String?)?.trim() ?? '';
    final assigned = ExamAssignmentCard.formatIso(context, contextData['assignedAt']);

    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExamSessionStatusBanner(status: sessionStatus),
          const SizedBox(height: 14),
          Text(examTitle, style: ExamSystemUi.listTitle(context)),
          if (className.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.class_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.teacherDashboardClassLabel(className),
                    style: ExamSystemUi.captionSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (teacherName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.studentClassTeacher(teacherName), style: ExamSystemUi.captionSecondary)),
              ],
            ),
          ],
          if (assigned != null) ...[
            const SizedBox(height: 6),
            Text(l10n.examCardAssignedAt(assigned), style: ExamSystemUi.captionMuted),
          ],
          if (sessionCreatedAt != null) ...[
            const SizedBox(height: 4),
            Text(l10n.examSessionCreatedAt(sessionCreatedAt!), style: ExamSystemUi.captionMuted),
          ],
          if (timing?.started != null) ...[
            const SizedBox(height: 4),
            Text(l10n.examCardSessionStarted(timing!.started!), style: ExamSystemUi.captionMuted),
          ],
          if (timing?.scheduledEnd != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.examSessionScheduledEndAt(timing!.scheduledEnd!),
              style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (timing?.ended != null) ...[
            const SizedBox(height: 4),
            Text(l10n.examCardLiveSessionEndedAt(timing!.ended!), style: ExamSystemUi.captionMuted),
          ],
          if (timing?.timeLimitBeforeStartMinutes != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.examSessionTimeLimitOnStart(timing!.timeLimitBeforeStartMinutes!),
              style: ExamSystemUi.captionMuted,
            ),
          ] else if (timing?.endsWhenTeacherEnds == true) ...[
            const SizedBox(height: 4),
            Text(l10n.examSessionEndsWhenTeacherEnds, style: ExamSystemUi.captionMuted),
          ],
          const SizedBox(height: 10),
          Text(
            '${l10n.examSessionRoomCode}: ${(roomCode ?? '').isEmpty ? '—' : roomCode}',
            style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
