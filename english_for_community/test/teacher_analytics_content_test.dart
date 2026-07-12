import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_for_community/feature/teacher/teacher_analytics_page.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_state.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_derived.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';

/// Full, populated charts payload — deliberately uses long student names, emails,
/// question stems and section tags to stress horizontal layout (the class of bug
/// that produced the RenderFlex paint error).
Map<String, dynamic> _stressCharts() => {
      'avgScore': 7.4,
      'trend': {'submissions': -63.0, 'avgScore': 0.4},
      'submissionsByDay': [
        for (var i = 0; i < 14; i++)
          {'date': '2026-06-${(20 + i).toString().padLeft(2, '0')}', 'count': i % 4},
      ],
      'scoreDistribution': const [
        {'range': '0–2', 'count': 4},
        {'range': '2–4', 'count': 3},
        {'range': '4–6', 'count': 12},
        {'range': '6–8', 'count': 58},
        {'range': '8–10', 'count': 87},
      ],
      'scoreByDay': const [
        {'date': '2026-06-24', 'avg': 6.9, 'count': 5},
        {'date': '2026-06-27', 'avg': 7.1, 'count': 4},
        {'date': '2026-07-01', 'avg': 6.7, 'count': 6},
        {'date': '2026-07-05', 'avg': 7.4, 'count': 8},
      ],
      'skillScoreAvg': const {
        'listening': 7.4,
        'reading': 6.9,
        'writing': 4.8,
        'speaking': 6.2,
        'grammar': 7.1,
      },
      'atRiskStudents': const [
        {
          'userId': 'u1',
          'fullName': 'Nguyễn Thị Hoàng Yến Vy Trần Lê Minh Châu Phương Anh',
          'email': 'nguyenthihoangyenvy.tranleminhchau@student.english4community.online',
          'avgPercent': null,
          'submittedCount': 0,
          'assignedCount': 26,
          'reason': 'not_submitting',
        },
        {
          'userId': 'u2',
          'fullName': 'Trần Văn A',
          'email': 'a@x.com',
          'avgPercent': 38.0,
          'submittedCount': 2,
          'assignedCount': 26,
          'reason': 'low_score',
        },
        {
          'userId': 'u3',
          'fullName': 'Lê Hoàng C',
          'email': 'c@x.com',
          'avgPercent': 56.0,
          'submittedCount': 11,
          'assignedCount': 26,
          'reason': 'late',
        },
      ],
      'hardestItems': const [
        {
          'label':
              'Choose the correct form of the verb in the present perfect versus past simple in this fairly long question stem that should truncate gracefully',
          'tag': 'Reading Comprehension — Passage 1: Environmental Issues (long section title)',
          'pctCorrect': 32.0,
          'attempts': 25,
        },
        {
          'label': 'Word stress in multi-syllable words',
          'tag': 'Listening',
          'pctCorrect': 47.0,
          'attempts': 24,
        },
      ],
      'integrityByRisk': const {'high': 3, 'medium': 7, 'low': 79},
      'integrityReasons': const {
        'tabSwitch': 9,
        'copyPaste': 4,
        'fullscreenExited': 2,
        'focusLossSeconds': 120,
      },
      'onTime': const {'onTime': 72, 'late': 21, 'missing': 7},
      'assignmentsByMode': const {'self_paced': 8, 'scheduled': 3, 'realtime': 1},
    };

TeacherAnalyticsState _stressState() {
  final charts = _stressCharts();
  final d = teacherAnalyticsDeriveCharts(charts);
  return TeacherAnalyticsState(
    status: TeacherAnalyticsStatus.success,
    period: 14,
    summary: const {
      'activeStudentCount': 26,
      'activeAssignments': 26,
      'pendingGradingCount': 38,
      'attempts': {'submitted': 176, 'inProgress': 14, 'total': 190},
    },
    charts: charts,
    submissionRows: d.submissionRows,
    scoreDistRows: d.scoreDistRows,
    scoreTrendRows: d.scoreTrendRows,
    submissionMaxY: d.submissionMaxY,
    scoreDistMaxY: d.scoreDistMaxY,
  );
}

Future<void> _pumpAt(WidgetTester tester, double width, {required Locale locale}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: buildAnalyticsContentForTest(_stressState()),
            ),
          ),
        ),
      ),
    ),
  );
  // Let post-frame grow callbacks + chart implicit animations settle.
  await tester.pump(const Duration(milliseconds: 1200));
}

void main() {
  // Give the test surface plenty of height so only *horizontal* layout is tested.
  setUp(() {});

  for (final width in <double>[1280, 960, 760, 640, 420]) {
    testWidgets('analytics content lays out without overflow @ ${width.toInt()}px (vi)',
        (tester) async {
      tester.view.physicalSize = Size(width * 3, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpAt(tester, width, locale: const Locale('vi'));
      expect(tester.takeException(), isNull, reason: 'overflow/paint error at width $width');
    });
  }

  testWidgets('analytics content lays out without overflow @ 760px (en)', (tester) async {
    tester.view.physicalSize = const Size(2280, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAt(tester, 760, locale: const Locale('en'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the smart-summary and key panels', (tester) async {
    tester.view.physicalSize = const Size(3840, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAt(tester, 1280, locale: const Locale('en'));
    expect(find.text('Students needing attention'), findsOneWidget);
    expect(find.text('Most-missed questions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
