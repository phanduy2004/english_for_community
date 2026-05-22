import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:flutter/material.dart';

/// Classroom-scoped assignment row for students (wraps [ExamAssignmentCard]).
class StudentExamAssignmentTile extends StatelessWidget {
  const StudentExamAssignmentTile({
    super.key,
    required this.assignment,
    required this.onOpen,
  });

  final Map<String, dynamic> assignment;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = assignment['id'] as String? ?? '';
    final mode = assignment['mode'] as String? ?? 'self_paced';
    final isRealtime = mode == 'realtime';
    final canStart = assignment['studentCanStart'] == true;
    final hint = assignment['studentStatusHint'] as String? ?? '';

    final attempt = assignment['myAttempt'];
    final attemptId = attempt is Map ? (attempt['id'] as String?) ?? '' : '';
    final attemptStatus = attempt is Map ? attempt['status'] as String? : null;
    final hasSubmittedAttempt = attemptStatus == 'submitted' && attemptId.isNotEmpty;

    String? actionLabel;
    var actionEnabled = false;

    if (hint == 'session_ended') {
      if (hasSubmittedAttempt) {
        actionLabel = l10n.examCardViewMySubmission;
        actionEnabled = true;
      }
    } else if (isRealtime) {
      actionLabel = l10n.examOpenLobby;
      actionEnabled = id.isNotEmpty && canStart;
    } else {
      actionLabel = l10n.studentExamStart;
      actionEnabled = id.isNotEmpty && canStart;
    }

    return ExamAssignmentCard(
      assignment: assignment,
      primaryActionLabel: actionLabel,
      primaryActionEnabled: actionEnabled,
      onPrimaryAction: actionEnabled ? onOpen : null,
    );
  }
}
