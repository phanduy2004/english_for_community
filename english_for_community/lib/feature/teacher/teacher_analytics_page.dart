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
import 'package:english_for_community/feature/progress/widgets/weekly_activity_bars_chart.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
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
                  : _AnalyticsContent(state: state),
        );
      },
    );
  }
}

// ── Content ─────────────────────────────────────────────────────────────────────

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.state});

  final TeacherAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Map<String, dynamic> summary = state.summary ?? const {};
    final Map<String, dynamic> charts = state.charts ?? const {};

    final skillAvg = charts['skillScoreAvg'] is Map
        ? Map<String, dynamic>.from(charts['skillScoreAvg'] as Map)
        : const <String, dynamic>{};
    final atRisk = _asMapList(charts['atRiskStudents']);
    final hardestItems = _asMapList(charts['hardestItems']);
    final integrityByRisk = charts['integrityByRisk'] is Map ? charts['integrityByRisk'] as Map : const {};
    final integrityReasons = charts['integrityReasons'] is Map
        ? Map<String, dynamic>.from(charts['integrityReasons'] as Map)
        : const <String, dynamic>{};
    final onTime = charts['onTime'] is Map
        ? Map<String, dynamic>.from(charts['onTime'] as Map)
        : const <String, dynamic>{};
    final modeBreakdown = charts['assignmentsByMode'] is Map ? charts['assignmentsByMode'] as Map : const {};

    // Panel subtitles + median marker (match the approved mockup).
    final periodSubmissions =
        state.submissionRows.fold<int>(0, (s, r) => s + ((r['count'] as num?)?.toInt() ?? 0));
    final avgPerDay = state.period > 0 ? periodSubmissions / state.period : 0.0;
    final gradedTotal =
        state.scoreDistRows.fold<int>(0, (s, r) => s + ((r['count'] as num?)?.toInt() ?? 0));
    final avgScoreVal = (charts['avgScore'] as num?)?.toDouble();

    // Score-trend panel + skill panel pair up on wide screens.
    final hasScoreTrend = state.scoreTrendRows.length >= 2;
    final hasSkill = skillAvg.isNotEmpty;

    Widget? scoreTrendPanel = hasScoreTrend
        ? _Panel(
            title: l10n.teacherAnalyticsScoreTrend,
            subtitle: l10n.teacherAnalyticsScoreTrendSub,
            child: SizedBox(height: 176, child: _ScoreTrendChart(rows: state.scoreTrendRows)),
          )
        : null;
    Widget? skillPanel = hasSkill
        ? _Panel(
            title: l10n.teacherAnalyticsSkillBreakdown,
            child: _SkillBreakdownSection(skillAvg: skillAvg),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── A · Overview ──────────────────────────────────────────────────
        _SectionHeader(l10n.teacherAnalyticsSectionOverview),
        const SizedBox(height: AppSpacing.s4),
        _KpiRow(summary: summary, charts: charts),
        const SizedBox(height: AppSpacing.s5),
        _SmartSummary(summary: summary, charts: charts, atRisk: atRisk, period: state.period),

        // ── B · Activity & scores ─────────────────────────────────────────
        const SizedBox(height: AppSpacing.s6),
        _SectionHeader(l10n.teacherAnalyticsSectionActivity),
        const SizedBox(height: AppSpacing.s4),
        _TwoCol(
          _Panel(
            title: l10n.teacherAnalyticsSubmissionsChart,
            subtitle: l10n.teacherAnalyticsPerDayAvg(avgPerDay.toStringAsFixed(1)),
            child: SizedBox(height: 176, child: _SubmissionsChart(rows: state.submissionRows)),
          ),
          _Panel(
            title: l10n.teacherAnalyticsScoreChart,
            subtitle: gradedTotal > 0 ? l10n.teacherAnalyticsGradedCount(gradedTotal) : null,
            child: SizedBox(
              height: 176,
              child: _ScoreDistBars(rows: state.scoreDistRows, avgScore: avgScoreVal),
            ),
          ),
        ),
        if (scoreTrendPanel != null || skillPanel != null) ...[
          const SizedBox(height: AppSpacing.s5),
          _TwoCol(scoreTrendPanel ?? skillPanel!, scoreTrendPanel != null ? skillPanel : null),
        ],

        // ── C · Students & questions ──────────────────────────────────────
        const SizedBox(height: AppSpacing.s6),
        _SectionHeader(l10n.teacherAnalyticsSectionStudents),
        const SizedBox(height: AppSpacing.s4),
        if (atRisk.isEmpty && hardestItems.isEmpty)
          _EmptyNote(
            icon: Icons.groups_outlined,
            text: l10n.teacherAnalyticsSectionStudentsEmpty,
          )
        else ...[
          if (atRisk.isNotEmpty)
            _Panel(
              title: l10n.teacherAnalyticsAtRiskTitle,
              leading: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
              child: _AtRiskTable(rows: atRisk),
            ),
          if (atRisk.isNotEmpty && hardestItems.isNotEmpty)
            const SizedBox(height: AppSpacing.s5),
          if (hardestItems.isNotEmpty)
            _Panel(
              title: l10n.teacherAnalyticsItemAnalysisTitle,
              subtitle: l10n.teacherAnalyticsItemAnalysisSub,
              leading: const Icon(Icons.help_outline, size: 16, color: AppColors.textSecondary),
              child: _ItemAnalysisList(rows: hardestItems),
            ),
        ],

        // ── D · Integrity & submissions ───────────────────────────────────
        const SizedBox(height: AppSpacing.s6),
        _SectionHeader(l10n.teacherAnalyticsSectionIntegrity),
        const SizedBox(height: AppSpacing.s4),
        _TwoCol(
          _Panel(
            title: l10n.teacherAnalyticsIntegrityChart,
            child: _IntegritySection(byRisk: integrityByRisk, reasons: integrityReasons),
          ),
          _Panel(
            title: l10n.teacherAnalyticsModeBreakdown,
            child: _ModeSection(modeBreakdown: modeBreakdown, onTime: onTime),
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
      ],
    );
  }

  static List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

/// Test-only entry point to render the analytics body (all panels) without the
/// scaffold/bloc/router, so widget tests can assert it lays out without overflow.
@visibleForTesting
Widget buildAnalyticsContentForTest(TeacherAnalyticsState state) => _AnalyticsContent(state: state);

// ── Layout primitives ───────────────────────────────────────────────────────────

/// Two panels side-by-side on wide screens, stacked on narrow ones.
class _TwoCol extends StatelessWidget {
  const _TwoCol(this.left, [this.right]);

  final Widget left;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    if (right == null) return left;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpacing.s5),
              Expanded(child: right!),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: AppSpacing.s5), right!],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TeacherWebUi.panelDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        // stretch → biểu đồ/bảng con nhận đúng bề ngang panel (fl_chart cần width bounded).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.s3)],
              Flexible(
                child: Text(title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TeacherWebUi.sectionTitle(context)),
              ),
              const SizedBox(width: AppSpacing.s4),
              if (subtitle != null)
                Flexible(
                  child: Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TeacherWebUi.webCaption(context).copyWith(color: AppColors.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          child,
        ],
      ),
    );
  }
}

/// Labeled group heading — titles one of the four analytics sections.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TeacherWebUi.webH2(context),
    );
  }
}

/// Compact inline empty-state note (surfaceSubtle card) — keeps a section
/// visible with an explanation instead of collapsing it when there is no data.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              text,
              style: TeacherWebUi.webBody(context).copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
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

// ── KPI row ────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.summary, required this.charts});

  final Map<String, dynamic> summary;
  final Map<String, dynamic> charts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attempts = summary['attempts'] is Map ? summary['attempts'] as Map : const {};
    // Backend đặt trend dưới charts.trend (không phải summary.trend).
    final trend = charts['trend'] is Map ? charts['trend'] as Map : const {};
    final submissionTrend = (trend['submissions'] as num?)?.toDouble();
    final avgScoreTrend = (trend['avgScore'] as num?)?.toDouble();
    final pendingGrading = (summary['pendingGradingCount'] as num?)?.toInt() ??
        (charts['pendingGradingCount'] as num?)?.toInt() ??
        0;
    final avgScore = (charts['avgScore'] as num?)?.toDouble();
    final submitted = (attempts['submitted'] as num?)?.toInt() ?? 0;
    final inProgress = (attempts['inProgress'] as num?)?.toInt() ?? 0;
    final started = submitted + inProgress;
    final completion = started > 0 ? (submitted / started * 100).round() : null;
    // Submissions KPI dùng số bài nộp TRONG KỲ để khớp badge trend (kỳ này vs kỳ
    // trước); summary.attempts.submitted là tổng mọi thời điểm nên lệch với %.
    final subByDay = charts['submissionsByDay'] is List ? charts['submissionsByDay'] as List : const [];
    final periodSubmissions = subByDay.fold<int>(
        0, (s, e) => s + ((e is Map ? (e['count'] as num?)?.toInt() : 0) ?? 0));

    return _KpiGrid(
      children: [
        _KpiCard(
          icon: Icons.groups_outlined,
          accent: AppColors.info,
          value: '${summary['activeStudentCount'] ?? 0}',
          label: l10n.teacherAnalyticsActiveStudents,
        ),
        _KpiCard(
          icon: Icons.star_outline,
          accent: AppColors.accent,
          value: avgScore != null ? avgScore.toStringAsFixed(1) : '—',
          suffix: avgScore != null ? '/10' : null,
          label: l10n.teacherAnalyticsAvgScore,
          trend: avgScoreTrend,
          trendIsPercent: false,
        ),
        _KpiCard(
          icon: Icons.donut_large_outlined,
          ringPercent: completion?.toDouble(),
          accent: AppColors.success,
          value: completion != null ? '$completion' : '—',
          suffix: completion != null ? '%' : null,
          label: l10n.teacherAnalyticsCompletion,
        ),
        _KpiCard(
          icon: Icons.check_circle_outline,
          accent: AppColors.success,
          value: '$periodSubmissions',
          label: l10n.teacherAnalyticsSubmissions,
          trend: submissionTrend,
          trendIsPercent: true,
        ),
        _KpiCard(
          icon: Icons.hourglass_empty_outlined,
          accent: AppColors.textSecondary,
          value: '$inProgress',
          label: l10n.teacherAnalyticsInProgress,
        ),
        _KpiCard(
          icon: Icons.fact_check_outlined,
          accent: AppColors.warning,
          value: '$pendingGrading',
          label: l10n.teacherAnalyticsPendingGrading,
          ctaLabel: l10n.teacherAnalyticsGradeNow,
          onTap: () => context.go(TeacherDashboardPage.routePath),
        ),
      ],
    );
  }
}

/// Dense KPI grid — packs the six compact cards across one row on wide web
/// viewports (≈190px min tile) instead of a fixed 4-col grid that leaves the
/// low-density cards oversized and full of whitespace.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = AppSpacing.s4;
        const minTile = 190.0;
        var cols = ((c.maxWidth + gap) / (minTile + gap)).floor();
        cols = cols.clamp(1, children.length);
        final itemW = cols <= 1 ? c.maxWidth : (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final w in children) SizedBox(width: itemW, child: w)],
        );
      },
    );
  }
}

/// Compact horizontal KPI card (icon/ring · value · label, with an inline trend
/// badge or "Grade now →" CTA). Deliberately dense — a KPI is one number, so the
/// card must stay small on web rather than eat a large tile of whitespace.
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.value,
    required this.label,
    required this.accent,
    this.icon,
    this.suffix,
    this.trend,
    this.trendIsPercent = true,
    this.ctaLabel,
    this.ringPercent,
    this.onTap,
  });

  final String value;
  final String label;
  final Color accent;
  final IconData? icon;
  final String? suffix;
  final double? trend;
  final bool trendIsPercent;
  final String? ctaLabel;
  final double? ringPercent; // 0..100 → progress ring instead of an icon box
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showTrend =
        trend != null && (trendIsPercent ? trend!.abs() >= 5 : trend!.abs() >= 0.1);

    final leading = ringPercent != null
        ? SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              value: (ringPercent! / 100).clamp(0, 1),
              strokeWidth: 3,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          )
        : Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Icon(icon, size: 16, color: accent),
          );

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TeacherWebUi.webKpiValue(context)),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 2),
                      Text(suffix!,
                          style: TeacherWebUi.webCaption(context)
                              .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ],
                    if (showTrend) ...[
                      const SizedBox(width: AppSpacing.s2),
                      _TrendBadge(value: trend!, isPercent: trendIsPercent),
                    ] else if (ctaLabel != null) ...[
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(ctaLabel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning)),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward, size: 12, color: AppColors.warning),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TeacherWebUi.webCaption(context)),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.hoverOverlay,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(decoration: TeacherWebUi.panelDecoration(), child: body),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.value, this.isPercent = true});

  final double value;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    final isUp = value > 0;
    final color = isUp ? AppColors.success : AppColors.danger;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;
    final text = isPercent ? '${value.abs().toStringAsFixed(0)}%' : value.abs().toStringAsFixed(1);
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
          Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Smart summary ───────────────────────────────────────────────────────────────

class _SmartSummary extends StatelessWidget {
  const _SmartSummary({
    required this.summary,
    required this.charts,
    required this.atRisk,
    required this.period,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> charts;
  final List<Map<String, dynamic>> atRisk;
  final int period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = <String>[];

    final avg = (charts['avgScore'] as num?)?.toDouble();
    if (avg != null) parts.add(l10n.teacherAnalyticsInsightAvg(avg.toStringAsFixed(1)));

    final skillAvg = charts['skillScoreAvg'] is Map
        ? Map<String, dynamic>.from(charts['skillScoreAvg'] as Map)
        : const <String, dynamic>{};
    final skillMeta = <(String, String)>[
      ('listening', l10n.teacherAnalyticsSkillListening),
      ('reading', l10n.teacherAnalyticsSkillReading),
      ('writing', l10n.teacherAnalyticsSkillWriting),
      ('speaking', l10n.teacherAnalyticsSkillSpeaking),
      ('grammar', l10n.teacherAnalyticsSkillGrammar),
    ];
    String? weakLabel;
    double? weakScore;
    for (final s in skillMeta) {
      final score = (skillAvg[s.$1] as num?)?.toDouble();
      if (score != null && (weakScore == null || score < weakScore)) {
        weakScore = score;
        weakLabel = s.$2;
      }
    }
    if (weakLabel != null && weakScore != null && weakScore < 6.5) {
      parts.add(l10n.teacherAnalyticsInsightWeakSkill(weakLabel, weakScore.toStringAsFixed(1)));
    }

    final notSubmitting = atRisk.where((r) => r['reason'] == 'not_submitting').length;
    if (notSubmitting > 0) parts.add(l10n.teacherAnalyticsInsightNotSubmitting(notSubmitting));

    final pending = (summary['pendingGradingCount'] as num?)?.toInt() ?? 0;
    if (pending > 0) parts.add(l10n.teacherAnalyticsInsightPending(pending));

    final text = parts.isEmpty ? l10n.teacherAnalyticsInsightEmpty : parts.join(' ');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Border phải ĐỒNG NHẤT màu khi có borderRadius (Flutter assert khi paint nếu
        // trộn màu như left=accent, còn lại=outline). Accent rail để thành widget con.
        border: Border.all(color: AppColors.outline),
        boxShadow: TeacherWebUi.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: AppColors.accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentTint,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accentDark),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.teacherAnalyticsSummaryTitle(period),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TeacherWebUi.sectionTitle(context)),
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            text,
                            style: TeacherWebUi.webBody(context)
                                .copyWith(color: AppColors.textSecondary, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _ScoreDistBars extends StatelessWidget {
  const _ScoreDistBars({required this.rows, this.avgScore});

  final List<Map<String, dynamic>> rows;
  final double? avgScore; // 0..10 → vị trí vạch điểm trung bình

  static const List<Color> _ramp = AppScoreScale.ramp;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(child: Text(context.l10n.teacherAnalyticsNoData, style: TeacherWebUi.webBody(context)));
    }
    final counts = [for (final r in rows) (r['count'] as num?)?.toInt() ?? 0];
    final total = counts.fold<int>(0, (s, c) => s + c);
    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);
    final markerFrac = avgScore != null ? (avgScore! / 10).clamp(0.0, 1.0) : null;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              // Chừa chỗ phía trên cột cho nhãn số + % (2 dòng text + gap ~ 38px).
              final maxBarH = (c.maxHeight - 38).clamp(8.0, c.maxHeight);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        Expanded(
                          child: _bar(
                            count: counts[i],
                            total: total,
                            barHeight: maxCount > 0 ? maxBarH * counts[i] / maxCount : 0,
                            color: _ramp[i % _ramp.length],
                          ),
                        ),
                    ],
                  ),
                  if (markerFrac != null)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: (c.maxWidth * markerFrac).clamp(0.0, c.maxWidth - 1),
                      child: _Median(
                        label: '${context.l10n.teacherAnalyticsAvgShort} ${avgScore!.toStringAsFixed(1)}',
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            for (final r in rows)
              Expanded(
                child: Text(
                  r['range'] as String? ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _bar({required int count, required int total, required double barHeight, required Color color}) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$count',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()])),
        Text('$pct%', style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: barHeight),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, h, _) => Container(
            width: 32,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Vertical dashed marker + label showing the class average on the score axis.
class _Median extends StatelessWidget {
  const _Median({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        Expanded(
          child: SizedBox(
            width: 1.4,
            child: CustomPaint(painter: _DashedVLinePainter(AppColors.primary)),
          ),
        ),
      ],
    );
  }
}

class _DashedVLinePainter extends CustomPainter {
  const _DashedVLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    const dash = 3.0, gap = 3.0;
    for (double y = 0; y < size.height; y += dash + gap) {
      canvas.drawLine(Offset(0, y), Offset(0, (y + dash).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVLinePainter old) => old.color != color;
}

// ── Score trend line chart ──────────────────────────────────────────────────────

class _ScoreTrendChart extends StatelessWidget {
  const _ScoreTrendChart({required this.rows});

  final List<Map<String, dynamic>> rows;

  String _dateLabel(int i) {
    final d = rows[i]['date'] as String? ?? '';
    return d.length >= 5 ? d.substring(5) : d;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.length < 2) {
      return Center(child: Text(l10n.teacherAnalyticsNoData, style: TeacherWebUi.webBody(context)));
    }
    final spots = <FlSpot>[
      for (var i = 0; i < rows.length; i++)
        FlSpot(i.toDouble(), ((rows[i]['avg'] as num?)?.toDouble() ?? 0).clamp(0, 10)),
    ];
    final lastIdx = spots.length - 1;
    // ~5 nhãn ngày rải đều trên trục X (thay vì chỉ đầu + cuối).
    final labelStep = ((rows.length - 1) / 4).ceil().clamp(1, 999);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rows.length - 1).toDouble(),
        minY: 0,
        maxY: 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2.5,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.chartGrid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 2.5,
              getTitlesWidget: (v, _) => (v == 0 || v == 5 || v == 10)
                  ? Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textMuted))
                  : const SizedBox.shrink(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: labelStep.toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_dateLabel(i), style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceInverse,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final i = s.x.round();
              if (i < 0 || i >= rows.length) return null;
              final avg = (rows[i]['avg'] as num?)?.toDouble() ?? 0;
              final count = (rows[i]['count'] as num?)?.toInt() ?? 0;
              return LineTooltipItem(
                '${_dateLabel(i)}\n',
                const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: '${avg.toStringAsFixed(1)}/10',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: '   ${l10n.teacherAnalyticsGradedCount(count)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
          getTouchedSpotIndicator: (bar, indexes) => indexes
              .map((i) => TouchedSpotIndicatorData(
                    const FlLine(color: AppColors.outlineStrong, strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (spot, pct, b, idx) => FlDotCirclePainter(
                        radius: 4.5,
                        color: AppColors.primary,
                        strokeColor: AppColors.surfaceCard,
                        strokeWidth: 2,
                      ),
                    ),
                  ))
              .toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            // Nối thẳng từng điểm (không làm cong) → thấy rõ điểm TB THỰC mỗi ngày.
            isCurved: false,
            color: AppColors.primary,
            barWidth: 2.4,
            dotData: FlDotData(
              show: true,
              // Chấm ở MỌI ngày để đọc từng điểm; điểm cuối tô nổi bật.
              getDotPainter: (spot, pct, bar, idx) => idx == lastIdx
                  ? FlDotCirclePainter(
                      radius: 4.5, color: AppColors.accent, strokeColor: AppColors.surfaceCard, strokeWidth: 2)
                  : FlDotCirclePainter(
                      radius: 2.6, color: AppColors.primary, strokeColor: AppColors.surfaceCard, strokeWidth: 1.5),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.accent.withValues(alpha: 0.16), AppColors.accent.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-skill horizontal bar breakdown ────────────────────────────────────────

class _SkillBreakdownSection extends StatelessWidget {
  const _SkillBreakdownSection({required this.skillAvg});

  final Map<String, dynamic> skillAvg;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final skillMeta = [
      ('listening', l10n.teacherAnalyticsSkillListening),
      ('reading', l10n.teacherAnalyticsSkillReading),
      ('writing', l10n.teacherAnalyticsSkillWriting),
      ('speaking', l10n.teacherAnalyticsSkillSpeaking),
      ('grammar', l10n.teacherAnalyticsSkillGrammar),
    ];

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

    return Column(
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
                    l10n.teacherAnalyticsWeakSkillHint(weakestSkill, weakestScore.toStringAsFixed(1)),
                    style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
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
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = AppScoreScale.forScore10(score);
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
                  widthFactor: (score / 10).clamp(0, 1),
                  child: Container(
                    height: 8,
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
            width: 32,
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── At-risk students table ──────────────────────────────────────────────────────

class _AtRiskTable extends StatelessWidget {
  const _AtRiskTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  String _reasonLabel(BuildContext context, String? reason) {
    final l10n = context.l10n;
    switch (reason) {
      case 'not_submitting':
        return l10n.teacherAnalyticsRiskNotSubmitting;
      case 'low_score':
        return l10n.teacherAnalyticsRiskLowScore;
      case 'late':
        return l10n.teacherAnalyticsRiskLate;
      default:
        return '';
    }
  }

  (Color, Color) _reasonColors(String? reason) {
    if (reason == 'late') return (AppColors.warning, AppColors.warningBg);
    return (AppColors.danger, AppColors.dangerBg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        // header
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: Row(
            children: [
              Expanded(child: _hdr(context, l10n.teacherAnalyticsColStudent)),
              SizedBox(width: 56, child: _hdr(context, l10n.teacherAnalyticsColAvg, right: true)),
              SizedBox(width: 68, child: _hdr(context, l10n.teacherAnalyticsColSubmitted, right: true)),
              SizedBox(width: 132, child: _hdr(context, l10n.teacherAnalyticsColAlert)),
            ],
          ),
        ),
        for (var i = 0; i < rows.length; i++) _row(context, rows[i], last: i == rows.length - 1),
      ],
    );
  }

  Widget _hdr(BuildContext context, String text, {bool right = false}) => Text(
        text.toUpperCase(),
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TeacherWebUi.webTableHead(context),
      );

  Widget _row(BuildContext context, Map<String, dynamic> r, {required bool last}) {
    final name = (r['fullName'] as String?)?.trim();
    final email = (r['email'] as String?)?.trim() ?? '';
    final display = (name != null && name.isNotEmpty) ? name : email;
    final initials = _initials(display);
    final avgPercent = (r['avgPercent'] as num?)?.toDouble();
    final submitted = (r['submittedCount'] as num?)?.toInt() ?? 0;
    final assigned = (r['assignedCount'] as num?)?.toInt() ?? 0;
    final reason = r['reason'] as String?;
    final (rc, rbg) = _reasonColors(reason);

    return Container(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.surfaceSubtle, shape: BoxShape.circle),
                  child: Text(initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      if (email.isNotEmpty && display != email)
                        Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerRight,
              child: _avgPill(avgPercent),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              '$submitted / $assigned',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          SizedBox(
            width: 132,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: rbg, borderRadius: BorderRadius.circular(AppRadius.chip)),
                child: Text(
                  _reasonLabel(context, reason),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: rc),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avgPill(double? avgPercent) {
    if (avgPercent == null) {
      return Text('—', style: TextStyle(fontSize: 12, color: AppColors.textMuted));
    }
    final color = AppScoreScale.forPercent(avgPercent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${avgPercent.toStringAsFixed(0)}%',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ── Item analysis ─────────────────────────────────────────────────────────────

class _ItemAnalysisList extends StatelessWidget {
  const _ItemAnalysisList({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) _row(context, l10n, rows[i], last: i == rows.length - 1),
      ],
    );
  }

  Widget _row(BuildContext context, dynamic l10n, Map<String, dynamic> r, {required bool last}) {
    final label = (r['label'] as String?) ?? '';
    final tag = (r['tag'] as String?)?.trim() ?? '';
    final pct = (r['pctCorrect'] as num?)?.toDouble() ?? 0;
    final attempts = (r['attempts'] as num?)?.toInt() ?? 0;
    final color = AppScoreScale.forPercent(pct);

    return Container(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (tag.isNotEmpty) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(tag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                    ],
                    Text(l10n.teacherAnalyticsAttemptsLabel(attempts),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          SizedBox(
            width: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.teacherAnalyticsCorrectLabel,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: AppColors.surfaceSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Integrity (risk chips + reasons) ──────────────────────────────────────────

class _IntegritySection extends StatelessWidget {
  const _IntegritySection({required this.byRisk, required this.reasons});

  final Map byRisk;
  final Map<String, dynamic> reasons;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final high = (byRisk['high'] as num?)?.toInt() ?? 0;
    final medium = (byRisk['medium'] as num?)?.toInt() ?? 0;
    final low = (byRisk['low'] as num?)?.toInt() ?? 0;
    final tabSwitch = (reasons['tabSwitch'] as num?)?.toInt() ?? 0;
    final copyPaste = (reasons['copyPaste'] as num?)?.toInt() ?? 0;
    final fullscreen = (reasons['fullscreenExited'] as num?)?.toInt() ?? 0;
    final hasReasons = tabSwitch > 0 || copyPaste > 0 || fullscreen > 0;
    // `integrityByRisk` thường chỉ có key 'unknown' (bài không giám sát) → high/medium/low
    // đều 0. Đừng hiện 3 chip "0/0/0" gây nhiễu khi thực ra chưa có dữ liệu chính trực.
    final hasRisk = high + medium + low > 0;

    if (!hasRisk && !hasReasons) {
      return Text(l10n.teacherAnalyticsNoData, style: TeacherWebUi.webBody(context));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRisk)
          Wrap(
            spacing: AppSpacing.s3,
            runSpacing: AppSpacing.s3,
            children: [
              _chip(l10n.teacherAnalyticsIntegrityHigh, high, AppColors.danger, AppColors.dangerBg),
              _chip(l10n.teacherAnalyticsIntegrityMedium, medium, AppColors.warning, AppColors.warningBg),
              _chip(l10n.teacherAnalyticsIntegrityLow, low, AppColors.success, AppColors.successBg),
            ],
          ),
        if (hasReasons) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(l10n.teacherAnalyticsIntegrityReasons.toUpperCase(),
              style: TextStyle(
                  fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.s2),
          if (tabSwitch > 0)
            _reasonRow(Icons.tab_outlined, l10n.teacherAnalyticsReasonTabSwitch, tabSwitch),
          if (copyPaste > 0)
            _reasonRow(Icons.content_paste_outlined, l10n.teacherAnalyticsReasonCopyPaste, copyPaste),
          if (fullscreen > 0)
            _reasonRow(Icons.fullscreen_exit_outlined, l10n.teacherAnalyticsReasonFullscreen, fullscreen),
        ],
      ],
    );
  }

  Widget _reasonRow(IconData icon, String label, int count) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
            Text('$count×', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );

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
          Text('$label: $count',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Assignment modes + on-time ────────────────────────────────────────────────

class _ModeSection extends StatelessWidget {
  const _ModeSection({required this.modeBreakdown, required this.onTime});

  final Map modeBreakdown;
  final Map<String, dynamic> onTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final modes = [
      ('homework', l10n.teacherAnalyticsModeHomework, AppColors.info),
      ('live', l10n.teacherAnalyticsModeLive, AppColors.danger),
      ('self_paced', l10n.teacherAnalyticsModeSelfPaced, AppColors.success),
      ('scheduled', l10n.teacherAnalyticsModeLive, AppColors.danger),
      ('realtime', l10n.teacherAnalyticsModeLive, AppColors.danger),
    ];

    final onTimeN = (onTime['onTime'] as num?)?.toInt() ?? 0;
    final lateN = (onTime['late'] as num?)?.toInt() ?? 0;
    final missingN = (onTime['missing'] as num?)?.toInt() ?? 0;
    final totalOt = onTimeN + lateN + missingN;

    final chips = modes.where((md) => modeBreakdown.containsKey(md.$1)).map((md) {
      final count = modeBreakdown[md.$1] ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: md.$3, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('${md.$2}  ', style: const TextStyle(fontSize: 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: md.$3.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('$count',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: md.$3)),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isEmpty)
          Text(l10n.teacherAnalyticsNoData, style: TeacherWebUi.webBody(context))
        else
          Wrap(spacing: AppSpacing.s3, runSpacing: AppSpacing.s3, children: chips),
        if (totalOt > 0) ...[
          const SizedBox(height: AppSpacing.s5),
          Text(l10n.teacherAnalyticsOnTimeTitle.toUpperCase(),
              style: TextStyle(
                  fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Row(
              children: [
                if (onTimeN > 0) Expanded(flex: onTimeN, child: Container(height: 8, color: AppColors.success)),
                if (lateN > 0) Expanded(flex: lateN, child: Container(height: 8, color: AppColors.warning)),
                if (missingN > 0) Expanded(flex: missingN, child: Container(height: 8, color: AppColors.outlineStrong)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s2,
            children: [
              _legend(AppColors.success, l10n.teacherAnalyticsOnTime, onTimeN),
              _legend(AppColors.warning, l10n.teacherAnalyticsLate, lateN),
              _legend(AppColors.outlineStrong, l10n.teacherAnalyticsMissing, missingN),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legend(Color color, String label, int count) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('$label $count',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      );
}
