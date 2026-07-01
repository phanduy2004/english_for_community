import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_question_strip.dart';

/// Keys that affect live-monitor roster tiles (ignore answers-only socket payloads).
const _rosterUiPatchKeys = {
  'status',
  'progressPercent',
  'answeredCount',
  'totalItems',
  'integrityRiskLevel',
  'skillStrips',
  'fullName',
  'email',
  'username',
  'attemptId',
};

bool liveMonitorPatchAffectsRosterUi(Map<String, dynamic> patch) {
  for (final key in patch.keys) {
    if (_rosterUiPatchKeys.contains(key)) return true;
  }
  return false;
}

bool liveMonitorRowVisualChanged(Map<String, dynamic> before, Map<String, dynamic> after) {
  for (final key in _rosterUiPatchKeys) {
    if (before[key] != after[key]) return true;
  }
  return false;
}

List<Map<String, dynamic>> filterLiveMonitorStudents(
  List<Map<String, dynamic>> students,
  TeacherLiveMonitorFilter filter,
) {
  switch (filter) {
    case TeacherLiveMonitorFilter.inProgress:
      return students.where((s) => s['status'] == 'in_progress').toList();
    case TeacherLiveMonitorFilter.submitted:
      return students
          .where((s) => ['submitted', 'expired', 'void'].contains(s['status']))
          .toList();
    case TeacherLiveMonitorFilter.flagged:
      return students
          .where((s) => s['integrityRiskLevel'] == 'high' || s['integrityRiskLevel'] == 'medium')
          .toList();
    case TeacherLiveMonitorFilter.all:
      return students;
  }
}

Map<String, Map<String, dynamic>> indexLiveMonitorStudents(
  List<Map<String, dynamic>> students,
) {
  final map = <String, Map<String, dynamic>>{};
  for (final s in students) {
    final id = s['userId']?.toString();
    if (id != null && id.isNotEmpty) map[id] = s;
  }
  return map;
}

Map<String, dynamic> summaryFromLiveMonitorStudents(List<Map<String, dynamic>> students) {
  final total = students.length;
  final inProgress = students.where((s) => s['status'] == 'in_progress').length;
  final submitted = students
      .where((s) => ['submitted', 'expired', 'void'].contains(s['status']))
      .length;
  final flagged = students
      .where((s) => s['integrityRiskLevel'] == 'high' || s['integrityRiskLevel'] == 'medium')
      .length;
  final avg = total == 0
      ? 0.0
      : students.fold<double>(0, (sum, s) => sum + ((s['progressPercent'] as num?)?.toDouble() ?? 0)) /
          total;
  return {
    'total': total,
    'inProgress': inProgress,
    'submitted': submitted,
    'flagged': flagged,
    'avgProgressPercent': (avg * 10).round() / 10,
  };
}

/// Re-parse skill strips only when the raw `skillStrips` reference changes (new socket patch),
/// otherwise reuse the cached parse — avoids both re-parsing every emit AND going stale.
Map<String, dynamic> enrichLiveMonitorStudentRow(Map<String, dynamic> row) {
  final next = Map<String, dynamic>.from(row);
  final raw = next['skillStrips'];
  if (raw is List && !identical(next['_parsedSkillStripsSource'], raw)) {
    next['_parsedSkillStrips'] = TeacherExamQuestionStripSection.parseStrips(raw);
    next['_parsedSkillStripsSource'] = raw;
  }
  return next;
}
