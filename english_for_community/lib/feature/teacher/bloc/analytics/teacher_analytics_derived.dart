List<Map<String, dynamic>> teacherAnalyticsParseChartRows(dynamic raw) {
  return (raw as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

double teacherAnalyticsChartMaxY(List<Map<String, dynamic>> rows, String countKey) {
  return rows.fold<double>(1, (m, r) {
    final c = (r[countKey] as num?)?.toDouble() ?? 0;
    return c > m ? c : m;
  });
}

TeacherAnalyticsChartDerived teacherAnalyticsDeriveCharts(Map<String, dynamic>? charts) {
  final submissionRows = teacherAnalyticsParseChartRows(charts?['submissionsByDay']);
  final scoreDistRows = teacherAnalyticsParseChartRows(charts?['scoreDistribution']);
  return TeacherAnalyticsChartDerived(
    submissionRows: submissionRows,
    scoreDistRows: scoreDistRows,
    submissionMaxY: teacherAnalyticsChartMaxY(submissionRows, 'count'),
    scoreDistMaxY: teacherAnalyticsChartMaxY(scoreDistRows, 'count'),
  );
}

class TeacherAnalyticsChartDerived {
  const TeacherAnalyticsChartDerived({
    required this.submissionRows,
    required this.scoreDistRows,
    required this.submissionMaxY,
    required this.scoreDistMaxY,
  });

  final List<Map<String, dynamic>> submissionRows;
  final List<Map<String, dynamic>> scoreDistRows;
  final double submissionMaxY;
  final double scoreDistMaxY;
}
