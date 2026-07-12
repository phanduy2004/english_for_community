import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:english_for_community/feature/admin/analytics/admin_analytics_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';

Map<String, dynamic> _mockData() => {
      'range': 'week',
      'kpis': const {
        'totalUsers': 1240,
        'students': 1180,
        'teachers': 42,
        'admins': 3,
        'activeUsers': 320,
        'newUsers': 58,
        'reportsPending': 7,
      },
      'trend': const {'newUsers': 12},
      'usersByRole': const {'student': 1180, 'teacher': 42, 'admin': 3},
      'newUsersByDay': const [
        {'date': '2026-07-04', 'count': 5},
        {'date': '2026-07-05', 'count': 9},
        {'date': '2026-07-06', 'count': 3},
        {'date': '2026-07-07', 'count': 12},
        {'date': '2026-07-08', 'count': 7},
        {'date': '2026-07-09', 'count': 15},
        {'date': '2026-07-10', 'count': 8},
      ],
    };

Future<void> _pumpAt(WidgetTester tester, double width, {required Locale locale}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: WorkspaceLayoutScope(
          useWebDensity: true,
          child: Center(
            child: SizedBox(
              width: width,
              child: buildAdminAnalyticsBodyForTest(_mockData()),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  for (final width in <double>[1280, 1024, 760]) {
    testWidgets('admin analytics body lays out without overflow @ ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width * 3, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpAt(tester, width, locale: const Locale('en'));
      expect(tester.takeException(), isNull, reason: 'overflow/paint error at width $width');
    });
  }

  testWidgets('renders platform KPIs and role breakdown', (tester) async {
    tester.view.physicalSize = const Size(3840, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAt(tester, 1280, locale: const Locale('en'));
    expect(find.text('Total users'), findsOneWidget);
    expect(find.text('Users by role'), findsOneWidget);
    expect(find.text('New users over time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
