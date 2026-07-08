import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_event.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_state.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_score_scale.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/progress/widgets/weekly_activity_bars_chart.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exams_list_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TeacherAnalyticsPage extends StatelessWidget {
  const TeacherAnalyticsPage({super.key});

  static const String routePath = '/teacher/analytics';
  static const String routeName = 'TeacherAnalyticsPage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherAnalyticsBloc>()..add(const TeacherAnalyticsLoadRequested()),
      child: const _TeacherAnalyticsView(),
    );
  }
}

class _TeacherAnalyticsView extends StatelessWidget {
  const _TeacherAnalyticsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<TeacherAnalyticsBloc, TeacherAnalyticsState>(
      buildWhen: (p, c) =>
          p.status != c.status || p.errorMessage != c.errorMessage || p.period != c.period,
      builder: (context, state) {
        final loading = state.status == TeacherAnalyticsStatus.loading;
        final error = state.status == TeacherAnalyticsStatus.error ? state.errorMessage : null;

        return TeacherPageScaffold(
          title: l10n.teacherAnalyticsTitle,
          breadcrumbs: [
            TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
            TeacherBreadcrumb(label: l10n.teacherAnalyticsTitle),
          ],
          actions: [
            _PeriodChips(period: state.period),
            const SizedBox(width: AppSpacing.s3),
            IconButton(
              onPressed: () => context
                  .read<TeacherAnalyticsBloc>()
                  .add(TeacherAnalyticsLoadRequested(period: state.period)),
              icon: const Icon(Icons.refresh_outlined, size: 20),
            ),
          ],
          body: loading
              ? TeacherSkeleton.page(TeacherSkeleton.analytics())
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error, style: TeacherWebUi.webBody(context)),
                          const SizedBox(height: AppSpacing.s5),
                          TeacherRetryButton(
                            onPressed: () => context
                                .read<TeacherAnalyticsBloc>()
                                .add(TeacherAnalyticsLoadRequested(period: state.period)),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BlocSelector<TeacherAnalyticsBloc, TeacherAnalyticsState, Map<String, dynamic>>(
                          selector: (s) => s.summary ?? const {},
                          builder: (context, summary) => BlocSelector<TeacherAnalyticsBloc,
                              TeacherAnalyticsState, Map<String, dynamic>?>(
                            selector: (s) => s.charts,
                            builder: (context, charts) =>
                                _KpiRow(summary: summary, charts: charts ?? const {}),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        _SectionTitle(l10n.teacherAnalyticsSubmissionsChart),
                        const SizedBox(height: AppSpacing.s4),
                        BlocSelector<TeacherAnalyticsBloc, TeacherAnalyticsState,
                            (List<Map<String, dynamic>>, double)>(
                          selector: (s) => (s.submissionRows, s.submissionMaxY),
                          builder: (context, data) => SizedBox(
                            height: 200,
                            child: _SubmissionsChart(rows: data.$1),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        _SectionTitle(l10n.teacherAnalyticsScoreChart),
                        const SizedBox(height: AppSpacing.s4),
                        BlocSelector<TeacherAnalyticsBloc, TeacherAnalyticsState,
                            (List<Map<String, dynamic>>, double)>(
                          selector: (s) => (s.scoreDistRows, s.scoreDistMaxY),
                          builder: (context, data) => SizedBox(
                            height: 200,
                            child: _ScoreDistChart(rows: data.$1, maxY: data.$2),
                          ),
                        ),
                        BlocSelector<TeacherAnalyticsBloc, TeacherAnalyticsState, Map<String, dynamic>?>(
                          selector: (s) => s.charts,
                          builder: (context, charts) {
                            if ((charts?['skillScoreAvg'] as Map?)?.isNotEmpty != true) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppSpacing.s6),
                                _SectionTitle(l10n.teacherAnalyticsSkillBreakdown),
                                const SizedBox(height: AppSpacing.s4),
                                _SkillBreakdownSection(data: charts),
                                const SizedBox(height: AppSpacing.s6),
                                _SectionTitle(l10n.teacherAnalyticsModeBreakdown),
                                const SizedBox(height: AppSpacing.s4),
                                _ModeBreakdownRow(data: charts),
                                const SizedBox(height: AppSpacing.s6),
                                _SectionTitle(l10n.teacherAnalyticsIntegrityChart),
                                const SizedBox(height: AppSpacing.s4),
                                _IntegrityRow(data: charts),
                                const SizedBox(height: AppSpacing.s6),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

// ── Period filter chips ────────────────────────────────────────────────────────

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.period});

  final int period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final periods = [
      (7, l10n.teacherAnalyticsPeriod7d),
      (14, l10n.teacherAnalyticsPeriod14d),
      (30, l10n.teacherAnalyticsPeriod30d),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: periods.map((p) {
        final selected = p.$1 == period;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: selected
                ? null
                : () => context
                    .read<TeacherAnalyticsBloc>()
                    .add(TeacherAnalyticsPeriodChanged(p.$1)),
            child: AnimatedContainer(
              duration: AppMotion.segment,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.outline,
                ),
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.onPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TeacherWebUi.sectionTitle(context));
  }
}

// ── KPI row ────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.summary, required this.charts});

  final Map<String, dynamic> summary;
  final Map<String, dynamic> charts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attempts = summary['attempts'] is Map ? summary['attempts'] as Map : {};
    // Backend đặt trend dưới charts.trend.submissions (không phải summary.trend) →
    // trước đây badge trend luôn null. Đọc từ charts.
    final trend = charts['trend'] is Map ? charts['trend'] as Map : {};
    final submissionTrend = (trend['submissions'] as num?)?.toDouble();
    final pendingGrading = (summary['pendingGradingCount'] as num?)?.toInt() ??
        (charts['pendingGradingCount'] as num?)?.toInt() ?? 0;

    return TeacherKpiGrid(
      children: [
        TeacherKpiCard(
          icon: Icons.groups_outlined,
          value: '${summary['activeStudentCount'] ?? 0}',
          label: l10n.teacherAnalyticsActiveStudents,
          accent: AppColors.primary,
        ),
        TeacherKpiCard(
          icon: Icons.assignment_outlined,
          value: '${summary['activeAssignments'] ?? 0}',
          label: l10n.teacherAnalyticsActiveAssignments,
          accent: AppColors.info,
        ),
        _TrendKpiCard(
          icon: Icons.check_circle_outline,
          value: '${attempts['submitted'] ?? 0}',
          label: l10n.teacherAnalyticsSubmissions,
          accent: AppColors.success,
          trendPct: submissionTrend,
        ),
        TeacherKpiCard(
          icon: Icons.pending_outlined,
          value: '$pendingGrading',
          label: l10n.teacherAnalyticsPendingGrading,
          accent: AppColors.warning,
        ),
      ],
    );
  }
}

class _TrendKpiCard extends StatelessWidget {
  const _TrendKpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.trendPct,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final double? trendPct;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TeacherKpiCard(icon: icon, value: value, label: label, accent: accent),
        if (trendPct != null && trendPct!.abs() >= 5)
          Positioned(
            top: 8,
            right: 8,
            child: _TrendBadge(pct: trendPct!),
          ),
      ],
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.pct});

  final double pct;

  @override
  Widget build(BuildContext context) {
    final isUp = pct > 0;
    final color = isUp ? AppColors.success : AppColors.danger;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: (isUp ? AppColors.successBg : AppColors.dangerBg),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '${pct.abs().toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Submissions bar chart ──────────────────────────────────────────────────────

class _SubmissionsChart extends StatelessWidget {
  const _SubmissionsChart({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(child: Text(context.l10n.teacherAnalyticsNoData, style: TeacherWebUi.webBody(context)));
    }
    // Dùng đúng widget biểu đồ ở màn mobile (cột "mọc" lên + đường xu hướng
    // nét đứt vẽ dần từ điểm đầu → điểm cuối) thay cho fl_chart, để có luôn
    // đường mô tả xu hướng số bài nộp theo ngày.
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final values = <int>[];
    final labels = <String>[];
    int? highlightIndex;
    for (var i = 0; i < rows.length; i++) {
      values.add(((rows[i]['count'] as num?) ?? 0).toInt());
      final d = rows[i]['date'] as String? ?? '';
      labels.add(d.length >= 5 ? d.substring(5) : d);
      if (d == today) highlightIndex = i;
    }
    return WeeklyActivityBarsChart(
      values: values,
      labels: labels,
      barColor: AppColors.chartBar,
      highlightIndex: highlightIndex,
      highlightColor: AppColors.chartHighlight,
    );
  }
}

// ── Score distribution chart ───────────────────────────────────────────────────

class _ScoreDistChart extends StatefulWidget {
  const _ScoreDistChart({required this.rows, required this.maxY});

  final List<Map<String, dynamic>> rows;
  final double maxY;

  static const List<Color> _bucketColors = AppScoreScale.ramp;

  @override
  State<_ScoreDistChart> createState() => _ScoreDistChartState();
}

class _ScoreDistChartState extends State<_ScoreDistChart> {
  List<BarChartGroupData>? _barGroups;
  String? _rowsKey;
  double? _maxY;
  bool _grown = false;
  bool _cachedGrown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  void didUpdateWidget(covariant _ScoreDistChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dữ liệu đổi → cho cột "mọc" lại từ 0 (fl_chart tween 0 → giá trị thật).
    if (_cacheKey(widget.rows) != _cacheKey(oldWidget.rows)) {
      _grown = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _grown = true);
      });
    }
  }

  String _cacheKey(List<Map<String, dynamic>> rows) =>
      rows.map((r) => '${r['range']}:${r['count']}').join('|');

  List<BarChartGroupData> _barGroupsFor(List<Map<String, dynamic>> rows) {
    final key = _cacheKey(rows);
    if (_barGroups != null && _rowsKey == key && _maxY == widget.maxY && _cachedGrown == _grown) {
      return _barGroups!;
    }
    _rowsKey = key;
    _maxY = widget.maxY;
    _cachedGrown = _grown;
    _barGroups = [
      for (var i = 0; i < rows.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _grown ? ((rows[i]['count'] as num?)?.toDouble() ?? 0) : 0,
              color: _ScoreDistChart._bucketColors[i % _ScoreDistChart._bucketColors.length],
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
    ];
    return _barGroups!;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    if (rows.isEmpty) {
      return Center(child: Text(context.l10n.teacherAnalyticsNoData, style: TeacherWebUi.webBody(context)));
    }
    return BarChart(
      BarChartData(
        maxY: widget.maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.chartGrid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => v % 1 == 0 && v > 0
                  ? Text('${v.toInt()}', style: const TextStyle(fontSize: 9))
                  : const SizedBox.shrink(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(rows[i]['range'] as String? ?? '', style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        barGroups: _barGroupsFor(rows),
      ),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
    );
  }
}

// ── Per-skill horizontal bar breakdown ────────────────────────────────────────

class _SkillBreakdownSection extends StatelessWidget {
  const _SkillBreakdownSection({this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final skillAvg = data?['skillScoreAvg'] is Map
        ? Map<String, dynamic>.from(data!['skillScoreAvg'] as Map)
        : <String, dynamic>{};

    final skillMeta = [
      ('listening', l10n.teacherAnalyticsSkillListening),
      ('reading', l10n.teacherAnalyticsSkillReading),
      ('writing', l10n.teacherAnalyticsSkillWriting),
      ('speaking', l10n.teacherAnalyticsSkillSpeaking),
      ('grammar', l10n.teacherAnalyticsSkillGrammar),
    ];

    // Find the weakest skill
    String? weakestSkill;
    double? weakestScore;
    for (final s in skillMeta) {
      final score = (skillAvg[s.$1] as num?)?.toDouble();
      if (score != null && score < 5.0) {
        if (weakestScore == null || score < weakestScore) {
          weakestSkill = s.$2;
          weakestScore = score;
        }
      }
    }

    return Container(
      decoration: TeacherWebUi.panelDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (weakestSkill != null && weakestScore != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(
                      l10n.teacherAnalyticsWeakSkillHint(
                          weakestSkill, weakestScore.toStringAsFixed(1)),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
          ],
          ...skillMeta.map((s) {
            final score = (skillAvg[s.$1] as num?)?.toDouble();
            if (score == null) return const SizedBox.shrink();
            return _SkillBar(label: s.$2, score: score);
          }),
        ],
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.label, required this.score});

  final String label;
  final double score;

  Color get _barColor {
    if (score < 5.0) return AppColors.danger;
    if (score < 7.0) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: score / 10,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _barColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          SizedBox(
            width: 32,
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _barColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode breakdown ─────────────────────────────────────────────────────────────

class _ModeBreakdownRow extends StatelessWidget {
  const _ModeBreakdownRow({this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = data?['assignmentsByMode'] is Map
        ? Map<String, dynamic>.from(data!['assignmentsByMode'] as Map)
        : <String, dynamic>{};

    if (m.isEmpty) {
      return TeacherEmptyCard(
        message: l10n.teacherAnalyticsNoData,
        icon: Icons.bar_chart_outlined,
        actionLabel: l10n.teacherEmptyInboxCta,
        onAction: () => context.go(TeacherDashboardPage.routePath),
      );
    }

    final modes = [
      ('homework', l10n.teacherAnalyticsModeHomework, AppColors.info),
      ('live', l10n.teacherAnalyticsModeLive, AppColors.danger),
      ('self_paced', l10n.teacherAnalyticsModeSelfPaced, AppColors.success),
    ];

    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: modes.where((md) => m.containsKey(md.$1)).map((md) {
        final count = m[md.$1] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: md.$3, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('${md.$2}  ', style: const TextStyle(fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: md.$3.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: md.$3,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Integrity flags ────────────────────────────────────────────────────────────

class _IntegrityRow extends StatelessWidget {
  const _IntegrityRow({this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = data?['integrityByRisk'] is Map
        ? Map<String, dynamic>.from(data!['integrityByRisk'] as Map)
        : {};
    if (m.isEmpty) {
      return TeacherEmptyCard(
        message: l10n.teacherAnalyticsNoData,
        icon: Icons.shield_outlined,
        actionLabel: l10n.teacherEmptyInboxCta,
        onAction: () => context.go(TeacherDashboardPage.routePath),
      );
    }
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: [
        _chip(l10n.teacherAnalyticsIntegrityHigh, m['high'] ?? 0, AppColors.danger, AppColors.dangerBg),
        _chip(l10n.teacherAnalyticsIntegrityMedium, m['medium'] ?? 0, AppColors.warning, AppColors.warningBg),
        _chip(l10n.teacherAnalyticsIntegrityLow, m['low'] ?? 0, AppColors.success, AppColors.successBg),
      ],
    );
  }

  Widget _chip(String label, dynamic count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: $count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
