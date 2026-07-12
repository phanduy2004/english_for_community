import 'package:flutter_test/flutter_test.dart';
import 'package:english_for_community/core/entity/progress_summary_entity.dart';

/// JSON hợp lệ cho statsGrid (6 card) — mỗi test clone rồi chỉnh.
Map<String, dynamic> validStatsJson() => {
      'vocabLearned': 12,
      'avgWritingScore': 6.5,
      'readingAccuracy': 90,
      'dictationAccuracy': 75,
      'speakingAccuracy': 42,
      'speakingFluency': 80,
      'lessonsCompleted': 7,
      'readingWpm': 125,
    };

Map<String, dynamic> validSummaryJson() => {
      'studyTime': {
        'todayMinutes': 15,
        'goalMinutes': 30,
        'totalMinutesInRange': 120,
        'progressPercent': 0.5,
      },
      'statsGrid': validStatsJson(),
      'weeklyChart': {
        'labels': ['T2', 'T3', 'T4'],
        'minutes': [10, 20, 30],
      },
      'callout': {'title': 'Great job!', 'message': "You've studied 15 minutes today."},
    };

void main() {
  group('StatsGridEntity.fromJson — 6 card', () {
    test('parse đúng giá trị & kiểu cho cả 6 card', () {
      final s = StatsGridEntity.fromJson(validStatsJson());
      expect(s.vocabLearned, 12);
      expect(s.readingAccuracy, 90);
      expect(s.dictationAccuracy, 75);
      expect(s.speakingAccuracy, 42);
      expect(s.speakingFluency, 80);
      expect(s.lessonsCompleted, 7);
      expect(s.avgWritingScore, 6.5);
      expect(s.avgWritingScore, isA<double>());
      expect(s.readingWpm, 125);
    });

    test('avgWritingScore nhận cả int (num) → double', () {
      final j = validStatsJson()..['avgWritingScore'] = 7; // int
      final s = StatsGridEntity.fromJson(j);
      expect(s.avgWritingScore, 7.0);
      expect(s.avgWritingScore, isA<double>());
    });

    test('speakingFluency & readingWpm mặc định 0 khi thiếu (đã có ?? 0)', () {
      final j = validStatsJson()
        ..remove('speakingFluency')
        ..remove('readingWpm');
      final s = StatsGridEntity.fromJson(j);
      expect(s.speakingFluency, 0);
      expect(s.readingWpm, 0);
    });

    // --- ROBUSTNESS (F3): thiếu field số → default 0, KHÔNG crash.
    test('THIẾU readingAccuracy → default 0 (null-safe)', () {
      final j = validStatsJson()..remove('readingAccuracy');
      expect(StatsGridEntity.fromJson(j).readingAccuracy, 0);
    });

    test('THIẾU avgWritingScore → default 0', () {
      final j = validStatsJson()..remove('avgWritingScore');
      expect(StatsGridEntity.fromJson(j).avgWritingScore, 0);
    });

    test('THIẾU vocabLearned/lessonsCompleted → default 0', () {
      expect(
        StatsGridEntity.fromJson(validStatsJson()..remove('vocabLearned')).vocabLearned,
        0,
      );
      expect(
        StatsGridEntity.fromJson(validStatsJson()..remove('lessonsCompleted')).lessonsCompleted,
        0,
      );
    });
  });

  group('StudyTimeEntity.fromJson', () {
    test('progressPercent nhận cả int → double', () {
      final s = StudyTimeEntity.fromJson({
        'todayMinutes': 10,
        'goalMinutes': 30,
        'totalMinutesInRange': 40,
        'progressPercent': 1, // int
      });
      expect(s.progressPercent, 1.0);
      expect(s.progressPercent, isA<double>());
    });
  });

  group('ProgressSummaryEntity.fromJson — full', () {
    test('parse đủ studyTime + statsGrid + weeklyChart + callout', () {
      final e = ProgressSummaryEntity.fromJson(validSummaryJson());
      expect(e.studyTime.todayMinutes, 15);
      expect(e.statsGrid.readingAccuracy, 90);
      expect(e.weeklyChart.labels, ['T2', 'T3', 'T4']);
      expect(e.weeklyChart.minutes, [10, 20, 30]);
      expect(e.callout.title, 'Great job!');
    });

    test('weeklyChart labels/minutes cùng độ dài', () {
      final e = ProgressSummaryEntity.fromJson(validSummaryJson());
      expect(e.weeklyChart.labels.length, e.weeklyChart.minutes.length);
    });
  });
}
