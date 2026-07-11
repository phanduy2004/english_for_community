import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/analytics/bloc/admin_analytics_bloc.dart';
import 'package:english_for_community/feature/admin/analytics/bloc/admin_analytics_event.dart';
import 'package:english_for_community/feature/admin/analytics/bloc/admin_analytics_state.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/layout/admin_skill_palette.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  static const String routeName = 'AdminAnalyticsPage';
  static const String routePath = '/admin/analytics';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminAnalyticsBloc>()..add(AdminAnalyticsLoadRequested(range: 'week')),
      child: const _AdminAnalyticsView(),
    );
  }
}

enum _Range { day, week, month }

class _AdminAnalyticsView extends StatefulWidget {
  const _AdminAnalyticsView();

  @override
  State<_AdminAnalyticsView> createState() => _AdminAnalyticsViewState();
}

class _AdminAnalyticsViewState extends State<_AdminAnalyticsView> {
  _Range _range = _Range.week;

  void _onRangeChanged(_Range r) {
    if (_range == r) return;
    setState(() => _range = r);
    context.read<AdminAnalyticsBloc>().add(AdminAnalyticsRangeChanged(r.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.adminAnalyticsTitle,
      scrollable: false,
      actions: [
        AdminSegmentedControl<_Range>(
          segments: _Range.values,
          selected: _range,
          onSelected: _onRangeChanged,
          labelBuilder: (r) => switch (r) {
            _Range.day => l10n.adminAnalyticsRangeDay,
            _Range.week => l10n.adminAnalyticsRangeWeek,
            _Range.month => l10n.adminAnalyticsRangeMonth,
          },
        ),
      ],
      body: BlocBuilder<AdminAnalyticsBloc, AdminAnalyticsState>(
        builder: (context, state) {
          if (state.status == AdminAnalyticsStatus.loading && state.data == null) {
            return AdminSkeleton.page(AdminSkeleton.cardList());
          }
          if (state.data == null) {
            return Center(
              child: AdminRetryButton(
                label: l10n.adminRetry,
                onPressed: () => context
                    .read<AdminAnalyticsBloc>()
                    .add(AdminAnalyticsLoadRequested(range: _range.name)),
              ),
            );
          }

          return _AdminAnalyticsBody(data: state.data!, range: _range);
        },
      ),
    );
  }
}

/// Test-only entry point to render the analytics body without scaffold/bloc.
@visibleForTesting
Widget buildAdminAnalyticsBodyForTest(Map<String, dynamic> data) =>
    _AdminAnalyticsBody(data: data, range: _Range.week);

class _AdminAnalyticsBody extends StatelessWidget {
  const _AdminAnalyticsBody({required this.data, required this.range});

  final Map<String, dynamic> data;
  final _Range range;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kpis = data['kpis'] is Map
        ? Map<String, dynamic>.from(data['kpis'] as Map)
        : const <String, dynamic>{};
    final trend = data['trend'] is Map
        ? Map<String, dynamic>.from(data['trend'] as Map)
        : const <String, dynamic>{};
    final usersByRole = data['usersByRole'] is Map
        ? Map<String, dynamic>.from(data['usersByRole'] as Map)
        : const <String, dynamic>{};
    final newUsersByDay = (data['newUsersByDay'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.s9),
      children: [
        _KpiRow(kpis: kpis, trend: trend),
        const SizedBox(height: AppSpacing.s6),
        _Panel(
          title: l10n.adminAnalyticsUsersByRole,
          subtitle: l10n.adminAnalyticsUsersByRoleSub,
          child: _RoleBars(usersByRole: usersByRole),
        ),
        const SizedBox(height: AppSpacing.s5),
        _Panel(
          title: l10n.adminAnalyticsNewUsersChart,
          child: SizedBox(height: 220, child: _NewUsersChart(rows: newUsersByDay, range: range)),
        ),
      ],
    );
  }
}

// ── KPI row ──────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpis, required this.trend});

  final Map<String, dynamic> kpis;
  final Map<String, dynamic> trend;

  int _i(String k) => (kpis[k] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final newUsersTrend = (trend['newUsers'] as num?)?.toInt();
    final trendMeta = newUsersTrend == null
        ? ''
        : '${newUsersTrend >= 0 ? '▲' : '▼'} ${newUsersTrend.abs()}%';

    return AdminKpiGrid(
      children: [
        AdminKpiCard(
          icon: Icons.groups_outlined,
          value: '${_i('totalUsers')}',
          label: l10n.adminAnalyticsTotalUsers,
          accent: AppColors.primary,
        ),
        AdminKpiCard(
          icon: Icons.school_outlined,
          value: '${_i('students')}',
          label: l10n.adminAnalyticsStudents,
          accent: AdminSkillPalette.users,
        ),
        AdminKpiCard(
          icon: Icons.co_present_outlined,
          value: '${_i('teachers')}',
          label: l10n.adminAnalyticsTeachers,
          accent: AppColors.success,
        ),
        AdminKpiCard(
          icon: Icons.bolt_outlined,
          value: '${_i('activeUsers')}',
          label: l10n.adminAnalyticsActiveUsers,
          accent: AdminSkillPalette.speaking,
        ),
        AdminKpiCard(
          icon: Icons.person_add_alt_outlined,
          value: '${_i('newUsers')}',
          label: l10n.adminAnalyticsNewUsers,
          meta: trendMeta,
          accent: AppColors.info,
        ),
        AdminKpiCard(
          icon: Icons.flag_outlined,
          value: '${_i('reportsPending')}',
          label: l10n.adminAnalyticsReportsPending,
          accent: AdminSkillPalette.reports,
        ),
      ],
    );
  }
}

// ── Panel ────────────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle});

  final String title;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminWebUi.cardDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AdminWebUi.webH2(context)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AdminWebUi.webCaption(context)),
          ],
          const SizedBox(height: AppSpacing.s5),
          child,
        ],
      ),
    );
  }
}

// ── Users by role (horizontal bars) ──────────────────────────────────────────

class _RoleBars extends StatelessWidget {
  const _RoleBars({required this.usersByRole});

  final Map<String, dynamic> usersByRole;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, int, Color)>[
      (l10n.adminAnalyticsRoleStudent, (usersByRole['student'] as num?)?.toInt() ?? 0, AdminSkillPalette.users),
      (l10n.adminAnalyticsRoleTeacher, (usersByRole['teacher'] as num?)?.toInt() ?? 0, AppColors.success),
      (l10n.adminAnalyticsRoleAdmin, (usersByRole['admin'] as num?)?.toInt() ?? 0, AppColors.primary),
    ];
    final total = rows.fold<int>(0, (s, r) => s + r.$2);
    if (total == 0) {
      return Text(l10n.adminAnalyticsNoData, style: AdminWebUi.webBody(context));
    }

    return Column(
      children: [
        for (final r in rows) _bar(context, r.$1, r.$2, total, r.$3),
      ],
    );
  }

  Widget _bar(BuildContext context, String label, int count, int total, Color color) {
    final frac = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: frac.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          SizedBox(
            width: 52,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: AdminWebUi.webBody(context).copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          SizedBox(
            width: 40,
            child: Text(
              '${(frac * 100).round()}%',
              textAlign: TextAlign.right,
              style: AdminWebUi.webCaption(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── New users over time (line chart) ─────────────────────────────────────────

class _NewUsersChart extends StatelessWidget {
  const _NewUsersChart({required this.rows, required this.range});

  final List<Map<String, dynamic>> rows;
  final _Range range;

  String _label(String raw) {
    if (range == _Range.day) {
      return raw.contains(':') ? '${int.tryParse(raw.split(':').first) ?? raw}h' : raw;
    }
    return raw.length >= 5 ? raw.substring(5) : raw;
  }

  @override
  Widget build(BuildContext context) {
    if (rows.length < 2) {
      return Center(child: Text(context.l10n.adminAnalyticsNoData, style: AdminWebUi.webBody(context)));
    }
    final counts = [for (final r in rows) (r['count'] as num?)?.toInt() ?? 0];
    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);
    final maxY = (maxCount * 1.25).ceilToDouble();
    final lastIdx = rows.length - 1;
    final spots = [
      for (var i = 0; i < counts.length; i++) FlSpot(i.toDouble(), counts[i].toDouble()),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rows.length - 1).toDouble(),
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.chartGrid, strokeWidth: 1, dashArray: const [5, 5]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => v % 1 == 0
                  ? Text('${v.toInt()}', style: AdminWebUi.webCaption(context).copyWith(fontSize: 10))
                  : const SizedBox.shrink(),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (rows.length - 1).toDouble().clamp(1, 999),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i != 0 && i != lastIdx) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_label(rows[i]['date'] as String? ?? ''),
                      style: AdminWebUi.webCaption(context).copyWith(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 2.4,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => idx == lastIdx
                  ? FlDotCirclePainter(
                      radius: 4, color: AppColors.info, strokeColor: AppColors.surfaceCard, strokeWidth: 2)
                  : FlDotCirclePainter(radius: 0, color: Colors.transparent),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.info.withValues(alpha: 0.18), AppColors.info.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
