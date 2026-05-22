import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:flutter/material.dart';

/// Labels for started / scheduled end / ended on the live session console card.
class TeacherExamSessionTimingLabels {
  const TeacherExamSessionTimingLabels({
    this.started,
    this.scheduledEnd,
    this.ended,
    this.timeLimitBeforeStartMinutes,
    this.endsWhenTeacherEnds = false,
  });

  final String? started;
  final String? scheduledEnd;
  final String? ended;
  final int? timeLimitBeforeStartMinutes;
  final bool endsWhenTeacherEnds;

  static TeacherExamSessionTimingLabels fromMaps(
    BuildContext context, {
    required String sessionStatus,
    Map<String, dynamic>? session,
    Map<String, dynamic>? assignmentContext,
  }) {
    final st = sessionStatus;
    final startedRaw = session?['startedAt']?.toString();
    final endedRaw = session?['endedAt']?.toString();
    final scheduledRaw = session?['scheduledEndAt']?.toString();

    String? scheduled = ExamAssignmentCard.formatIso(context, scheduledRaw);
    if (scheduled == null && startedRaw != null) {
      final schedule = assignmentContext?['schedule'];
      final sec = schedule is Map ? schedule['effectiveTimeLimitSeconds'] : null;
      if (sec is num && sec > 0) {
        final start = DateTime.tryParse(startedRaw);
        if (start != null) {
          final end = start.toLocal().add(Duration(seconds: sec.toInt()));
          scheduled = ExamAssignmentCard.formatIso(context, end.toIso8601String());
        }
      }
    }

    final started = ExamAssignmentCard.formatIso(context, startedRaw);
    final ended = ExamAssignmentCard.formatIso(context, endedRaw);

    int? limitMins;
    final tls = session?['timeLimitSeconds'];
    if (tls is num && tls > 0) {
      limitMins = (tls / 60).ceil();
    } else {
      final schedule = assignmentContext?['schedule'];
      final sec = schedule is Map ? schedule['effectiveTimeLimitSeconds'] : null;
      if (sec is num && sec > 0) limitMins = (sec / 60).ceil();
    }

    final isLobby = st == 'lobby';
    final isLive = st == 'live';
    final isEnded = st == 'closed' || st == 'grading' || st == 'canceled';

    return TeacherExamSessionTimingLabels(
      started: (isLive || isEnded) && started != null ? started : null,
      scheduledEnd: isLive && scheduled != null ? scheduled : null,
      ended: isEnded && ended != null ? ended : null,
      timeLimitBeforeStartMinutes: isLobby && started == null && limitMins != null ? limitMins : null,
      endsWhenTeacherEnds: isLobby && started == null && limitMins == null && scheduled == null,
    );
  }
}
