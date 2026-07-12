import 'package:flutter_test/flutter_test.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_derived.dart';

void main() {
  group('teacherAnalyticsParseChartRows', () {
    test('returns an empty list for null / non-list input', () {
      expect(teacherAnalyticsParseChartRows(null), isEmpty);
      expect(teacherAnalyticsParseChartRows('nope'), isEmpty);
    });

    test('coerces each element to a typed Map', () {
      final rows = teacherAnalyticsParseChartRows([
        {'date': '2026-07-01', 'count': 3},
      ]);
      expect(rows, hasLength(1));
      expect(rows.first['count'], 3);
      expect(rows.first, isA<Map<String, dynamic>>());
    });
  });

  group('teacherAnalyticsChartMaxY', () {
    test('never returns below 1 (safe chart floor even when all zero)', () {
      expect(teacherAnalyticsChartMaxY(const [], 'count'), 1);
      expect(
        teacherAnalyticsChartMaxY(const [
          {'count': 0},
        ], 'count'),
        1,
      );
    });

    test('returns the maximum value for the given key', () {
      final max = teacherAnalyticsChartMaxY(const [
        {'count': 2},
        {'count': 9},
        {'count': 5},
      ], 'count');
      expect(max, 9);
    });
  });

  group('teacherAnalyticsDeriveCharts', () {
    test('yields empty series and floor maxY for null charts', () {
      final d = teacherAnalyticsDeriveCharts(null);
      expect(d.submissionRows, isEmpty);
      expect(d.scoreDistRows, isEmpty);
      expect(d.scoreTrendRows, isEmpty);
      expect(d.submissionMaxY, 1);
      expect(d.scoreDistMaxY, 1);
    });

    test('parses submissions + score distribution with correct maxY', () {
      final d = teacherAnalyticsDeriveCharts({
        'submissionsByDay': [
          {'date': '2026-07-01', 'count': 1},
          {'date': '2026-07-02', 'count': 4},
        ],
        'scoreDistribution': [
          {'range': '0–2', 'count': 3},
          {'range': '8–10', 'count': 87},
        ],
      });
      expect(d.submissionRows, hasLength(2));
      expect(d.submissionMaxY, 4);
      expect(d.scoreDistMaxY, 87);
    });

    test('score-trend keeps ONLY days with graded submissions (count > 0)', () {
      final d = teacherAnalyticsDeriveCharts({
        'scoreByDay': [
          {'date': '2026-07-01', 'avg': 7.2, 'count': 5},
          {'date': '2026-07-02', 'avg': 0, 'count': 0}, // no graded submissions → dropped
          {'date': '2026-07-03', 'avg': 6.8, 'count': 3},
        ],
      });
      expect(d.scoreTrendRows, hasLength(2));
      expect(d.scoreTrendRows.map((r) => r['date']), ['2026-07-01', '2026-07-03']);
    });

    test('score-trend preserves the avg value used to plot the line', () {
      final d = teacherAnalyticsDeriveCharts({
        'scoreByDay': [
          {'date': '2026-07-01', 'avg': 7.4, 'count': 2},
        ],
      });
      expect(d.scoreTrendRows.single['avg'], 7.4);
    });

    test('missing scoreByDay key yields an empty trend series (panel hides)', () {
      final d = teacherAnalyticsDeriveCharts({
        'submissionsByDay': [
          {'date': '2026-07-01', 'count': 1},
        ],
      });
      expect(d.scoreTrendRows, isEmpty);
    });
  });
}
