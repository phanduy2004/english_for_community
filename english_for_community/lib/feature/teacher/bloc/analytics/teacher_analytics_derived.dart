List<Map<String, dynamic>> teacherAnalyticsParseChartRows(dynamic raw) {
  // Defensive: a broken/absent payload (null, or an unexpected non-list type) must
  // yield an empty series, never throw — the panels just hide instead of crashing.
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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
  // Score trend line — keep only days that actually have graded submissions so the
  // line reflects real data points, not zero-filled gaps.
  final scoreTrendRows = teacherAnalyticsParseChartRows(charts?['scoreByDay'])
      .where((r) => ((r['count'] as num?)?.toInt() ?? 0) > 0)
      .toList();
  return TeacherAnalyticsChartDerived(
    submissionRows: submissionRows,
    scoreDistRows: scoreDistRows,
    scoreTrendRows: scoreTrendRows,
    submissionMaxY: teacherAnalyticsChartMaxY(submissionRows, 'count'),
    scoreDistMaxY: teacherAnalyticsChartMaxY(scoreDistRows, 'count'),
  );
}

class TeacherAnalyticsChartDerived {
  const TeacherAnalyticsChartDerived({
    required this.submissionRows,
    required this.scoreDistRows,
    required this.scoreTrendRows,
    required this.submissionMaxY,
    required this.scoreDistMaxY,
  });

  final List<Map<String, dynamic>> submissionRows;
  final List<Map<String, dynamic>> scoreDistRows;
  final List<Map<String, dynamic>> scoreTrendRows;
  final double submissionMaxY;
  final double scoreDistMaxY;
}
