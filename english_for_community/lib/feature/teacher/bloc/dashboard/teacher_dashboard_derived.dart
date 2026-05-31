import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_list_utils.dart';

bool teacherDashboardPassesAssignmentFilter(
  Map<String, dynamic> m,
  TeacherDashboardAssignmentFilter filter,
) {
  switch (filter) {
    case TeacherDashboardAssignmentFilter.all:
      return true;
    case TeacherDashboardAssignmentFilter.selfPaced:
      return (m['mode'] as String?) == 'self_paced';
    case TeacherDashboardAssignmentFilter.scheduled:
      return (m['mode'] as String?) == 'scheduled';
    case TeacherDashboardAssignmentFilter.realtime:
      return (m['mode'] as String?) == 'realtime';
    case TeacherDashboardAssignmentFilter.publicLink:
      return (m['audience'] as String?) == 'public_link';
  }
}

String teacherDashboardExamTitleFromAssignment(Map<String, dynamic> m, {String fallback = 'Exam'}) {
  final exam = m['examId'];
  if (exam is Map) {
    final t = (exam['title'] as String?)?.trim();
    if (t != null && t.isNotEmpty) return t;
  }
  return fallback;
}

List<Map<String, dynamic>> teacherDashboardFilterAssignments({
  required List<dynamic> assignments,
  required String searchQuery,
  required TeacherDashboardAssignmentFilter assignmentFilter,
  required String? classroomFilterId,
  String examTitleFallback = 'Exam',
}) {
  final q = searchQuery.trim().toLowerCase();
  final out = <Map<String, dynamic>>[];
  for (final raw in assignments) {
    final m = Map<String, dynamic>.from(raw as Map);
    if (!TeacherAssignmentListUtils.isActiveListItem(m)) continue;
    if (!TeacherAssignmentListUtils.matchesClassroomFilter(m, classroomFilterId)) continue;
    if (!teacherDashboardPassesAssignmentFilter(m, assignmentFilter)) continue;
    if (q.isNotEmpty) {
      final title = teacherDashboardExamTitleFromAssignment(m, fallback: examTitleFallback).toLowerCase();
      if (!title.contains(q)) continue;
    }
    out.add(m);
  }
  return out;
}
