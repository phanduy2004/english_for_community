import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _student({
  String status = 'in_progress',
  String? risk,
  String userId = 'u1',
  int? tabSwitchCount,
}) =>
    {
      'userId': userId,
      'status': status,
      if (risk != null) 'integrityRiskLevel': risk,
      if (tabSwitchCount != null) 'tabSwitchCount': tabSwitchCount,
    };

void main() {
  group('summaryFromLiveMonitorStudents', () {
    test('flagged counts high + medium only', () {
      final students = [
        _student(risk: 'high', userId: 'a'),
        _student(risk: 'medium', userId: 'b'),
        _student(risk: 'low', userId: 'c'),
        _student(userId: 'd'), // no risk key
      ];
      final summary = summaryFromLiveMonitorStudents(students);
      expect(summary['flagged'], 2);
      expect(summary['total'], 4);
    });
  });

  group('filterLiveMonitorStudents(flagged)', () {
    test('returns only high + medium', () {
      final students = [
        _student(risk: 'high', userId: 'a'),
        _student(risk: 'medium', userId: 'b'),
        _student(risk: 'low', userId: 'c'),
        _student(userId: 'd'),
      ];
      final flagged = filterLiveMonitorStudents(students, TeacherLiveMonitorFilter.flagged);
      expect(flagged.map((s) => s['userId']).toList(), ['a', 'b']);
    });
  });

  group('liveMonitorRowVisualChanged (C1: detail counts must trigger repaint)', () {
    test('true when tabSwitchCount changes', () {
      final before = _student(tabSwitchCount: 1);
      final after = _student(tabSwitchCount: 2);
      expect(liveMonitorRowVisualChanged(before, after), isTrue);
    });

    test('true when focusLossSeconds / copyPasteAttempts change', () {
      expect(
        liveMonitorRowVisualChanged({'focusLossSeconds': 0}, {'focusLossSeconds': 30}),
        isTrue,
      );
      expect(
        liveMonitorRowVisualChanged({'copyPasteAttempts': 0}, {'copyPasteAttempts': 1}),
        isTrue,
      );
    });

    test('true when integrityRiskLevel changes', () {
      final before = _student(risk: 'low');
      final after = _student(risk: 'high');
      expect(liveMonitorRowVisualChanged(before, after), isTrue);
    });

    test('false when only a non-roster key changes', () {
      expect(
        liveMonitorRowVisualChanged({'answersDetail': 1}, {'answersDetail': 2}),
        isFalse,
      );
    });
  });

  group('liveMonitorPatchAffectsRosterUi', () {
    test('true when patch carries a detail count', () {
      expect(liveMonitorPatchAffectsRosterUi({'tabSwitchCount': 3}), isTrue);
      expect(liveMonitorPatchAffectsRosterUi({'focusLossSeconds': 10}), isTrue);
    });

    test('false for answers-only patch', () {
      expect(liveMonitorPatchAffectsRosterUi({'answersDetail': 1}), isFalse);
    });
  });
}
