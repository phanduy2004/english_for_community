/// Attempt list filter for [TeacherGradingHubBloc].
enum TeacherGradingHubFilter {
  all,
  inProgress,
  submitted,
  pendingManual,
  finalized,
  released,
  partial,
}

bool teacherGradingHubMatchesFilter(Map<String, dynamic> m, TeacherGradingHubFilter filter) {
  final status = m['status'] as String? ?? '';
  final gs = m['gradingState'] as String? ?? '';
  final released = m['resultsReleased'] == true;
  final meta = m['meta'];
  final completeness = meta is Map ? meta['submitCompleteness'] as String? : null;

  switch (filter) {
    case TeacherGradingHubFilter.all:
      return true;
    case TeacherGradingHubFilter.inProgress:
      return status == 'in_progress';
    case TeacherGradingHubFilter.submitted:
      return status == 'submitted';
    case TeacherGradingHubFilter.pendingManual:
      return gs == 'pending_manual' || gs == 'pending_ai';
    case TeacherGradingHubFilter.finalized:
      return gs == 'finalized' && !released;
    case TeacherGradingHubFilter.released:
      return released;
    case TeacherGradingHubFilter.partial:
      return completeness == 'partial';
  }
}

List<Map<String, dynamic>> teacherGradingHubVisibleAttempts(
  List<Map<String, dynamic>> attempts,
  TeacherGradingHubFilter filter,
) =>
    attempts.where((m) => teacherGradingHubMatchesFilter(m, filter)).toList();
