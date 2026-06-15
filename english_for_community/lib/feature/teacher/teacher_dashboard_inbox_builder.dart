import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dashboard_layout.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_list_utils.dart';
import 'package:english_for_community/feature/teacher/teacher_calendar_page.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_attempt_grade_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_console_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum TeacherInboxFilter { all, grading, live }

String? _classroomNameForAssignment(String assignmentId, List<dynamic> assignments) {
  for (final raw in assignments) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    if ((m['id'] as String? ?? '') != assignmentId) continue;
    return TeacherAssignmentListUtils.classroomNameFromAssignment(m);
  }
  return null;
}

String? _formatSubmittedAt(BuildContext context, DateTime? dt) {
  if (dt == null) return null;
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_Hm().format(dt.toLocal());
}

String _resolveClassroomLabel(
  AppLocalizations l10n, {
  String? fromItem,
  String? fromAssignmentLookup,
}) {
  final name = (fromItem ?? fromAssignmentLookup ?? '').trim();
  if (name.isNotEmpty) return name;
  return l10n.teacherInboxPublicAssignment;
}

List<TeacherDashboardInboxEntry> buildTeacherDashboardInboxEntries({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<TeacherGradingQueueItem> gradingQueue,
  required List<dynamic> assignments,
  required Map<String, dynamic>? actionItems,
  required List<dynamic> classrooms,
  required String Function(AppLocalizations l10n, TeacherGradingQueueItem it) gradingChipLabel,
  required String Function(Map<String, dynamic> m) examTitleFromAssignment,
  required String Function(Map<String, dynamic> m) classNameFromAssignment,
  TeacherInboxFilter filter = TeacherInboxFilter.all,
}) {
  final entries = <TeacherDashboardInboxEntry>[];

  if (filter == TeacherInboxFilter.all || filter == TeacherInboxFilter.grading) {
    for (final it in gradingQueue) {
      final className = _resolveClassroomLabel(
        l10n,
        fromItem: it.classroomName,
        fromAssignmentLookup: _classroomNameForAssignment(it.assignmentId, assignments),
      );
      entries.add(
        TeacherDashboardInboxEntry(
          kind: TeacherDashboardInboxKind.grading,
          title: it.studentLabel,
          subtitle: it.assignmentTitle,
          classroomName: className,
          timestamp: _formatSubmittedAt(context, it.submittedAt),
          badge: gradingChipLabel(l10n, it),
          onTap: () => context.push(
            TeacherExamAttemptGradePage.location(it.assignmentId, it.attemptId),
          ),
        ),
      );
    }
  }

  if (filter == TeacherInboxFilter.all || filter == TeacherInboxFilter.live) {
    final liveAssignments = assignments
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .where(TeacherAssignmentListUtils.hasOngoingLiveSession)
        .toList();

    for (final m in liveAssignments) {
      final id = m['id'] as String? ?? '';
      final title = examTitleFromAssignment(m);
      final className = _resolveClassroomLabel(
        l10n,
        fromItem: classNameFromAssignment(m),
      );
      entries.add(
        TeacherDashboardInboxEntry(
          kind: TeacherDashboardInboxKind.live,
          title: title,
          subtitle: l10n.teacherDashboardLiveWaitingSession,
          classroomName: className,
          badge: l10n.examModeRealtime,
          onTap: id.isEmpty ? () {} : () => context.push('${TeacherExamSessionConsolePage.routePath}/$id'),
        ),
      );
    }
  }

  if (filter == TeacherInboxFilter.all) {
    final pending = (actionItems?['pendingJoins'] as List? ?? []).length;
    if (pending > 0) {
      entries.add(
        TeacherDashboardInboxEntry(
          kind: TeacherDashboardInboxKind.pendingJoin,
          title: l10n.teacherDashboardPendingJoinsCount(pending),
          subtitle: l10n.teacherMyClassrooms,
          badge: l10n.teacherDashboardPendingJoins,
          onTap: () => _openFirstClassroom(context, classrooms),
        ),
      );
    }

    final dueSoon = (actionItems?['dueSoon'] as List? ?? []).length;
    if (dueSoon > 0) {
      entries.add(
        TeacherDashboardInboxEntry(
          kind: TeacherDashboardInboxKind.dueSoon,
          title: l10n.teacherDashboardDueSoonCount(dueSoon),
          subtitle: l10n.teacherDashboardAssignmentHubSubtitle,
          badge: l10n.examModeScheduled,
          onTap: () => context.push(TeacherCalendarPage.routePath),
        ),
      );
    }
  }

  return entries;
}

void openFirstTeacherClassroom(BuildContext context, List<dynamic> classrooms) {
  _openFirstClassroom(context, classrooms);
}

void _openFirstClassroom(BuildContext context, List<dynamic> classrooms) {
  if (classrooms.isEmpty) return;
  final m = Map<String, dynamic>.from(classrooms.first as Map);
  final id = m['id'] as String? ?? '';
  if (id.isEmpty) return;
  context.push('${TeacherClassroomDetailPage.routePath}/$id');
}
