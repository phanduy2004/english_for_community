import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entity/progress_summary_entity.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/ui/animation/animated_status_container.dart';
import '../../../core/ui/widget/app_skeleton.dart';
import '../../progress/bloc/progress_bloc.dart';
import '../../progress/bloc/progress_event.dart';
import '../../progress/bloc/progress_state.dart';
import '../../progress/progress_report_page.dart';
import '../../progress/widgets/weekly_activity_bars_chart.dart';
import '../../../core/locale/l10n_context.dart';

/// Card preview tiến độ tuần — **dùng chung** [`WeeklyActivityBarsChart`] với màn Progress (Activity),
/// kèm streak / mục tiêu ngày và link mở Progress.
class HomeStudyDashboard extends StatelessWidget {
  final int streak;
  final int dailyProgress;
  final int dailyGoal;
  final Color textMain;
  final Color textMuted;
  final Color primaryColor;

  const HomeStudyDashboard({
    super.key,
    required this.streak,
    required this.dailyProgress,
    required this.dailyGoal,
    required this.textMain,
    required this.textMuted,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        final statusKey =
            '${state.status.name}_${state.summary != null}_${state.errorMessage ?? ''}';

        Widget body;
        if (state.status == ProgressStatus.loading && state.summary == null) {
          body = const WeeklyStudyChartSkeleton();
        } else if (state.status == ProgressStatus.error || state.summary == null) {
          body = _RetryCard(
            textMain: textMain,
            textMuted: textMuted,
            onRetry: () =>
                context.read<ProgressBloc>().add(const FetchProgressData(range: 'week')),
          );
        } else {
          final summary = state.summary!;
          body = _ChartCard(
            summary: summary,
            streak: streak,
            dailyProgress: dailyProgress,
            dailyGoal: dailyGoal,
            textMain: textMain,
            textMuted: textMuted,
            primaryColor: primaryColor,
          );
        }

        return AnimatedStatusContainer(statusKey: statusKey, child: body);
      },
    );
  }
}

class _RetryCard extends StatelessWidget {
  final Color textMain;
  final Color textMuted;
  final VoidCallback onRetry;

  const _RetryCard({
    required this.textMain,
    required this.textMuted,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.couldNotLoadStudyChart,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textMuted),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry, style: TextStyle(color: textMain, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final ProgressSummaryEntity summary;
  final int streak;
  final int dailyProgress;
  final int dailyGoal;
  final Color textMain;
  final Color textMuted;
  final Color primaryColor;

  const _ChartCard({
    required this.summary,
    required this.streak,
    required this.dailyProgress,
    required this.dailyGoal,
    required this.textMain,
    required this.textMuted,
    required this.primaryColor,
  });

  String _fmtMinutes(int m) {
    if (m <= 0) return '0 min';
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  @override
  Widget build(BuildContext context) {
    final chart = summary.weeklyChart;
    final study = summary.studyTime;
    final minutes = chart.minutes;
    final labels = chart.labels;
    final n = math.min(minutes.length, labels.length);
    if (n == 0) {
      return _emptyCard(context);
    }

    final totalWeek = study.totalMinutesInRange;
    final hi = n > 0 ? n - 1 : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.l10n.weeklyActivity,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textMain),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.outlineMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.l10n.sameChartBadge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.weeklySummaryLine(_fmtMinutes(totalWeek), dailyProgress, dailyGoal),
                      style: TextStyle(fontSize: 12, height: 1.35, color: textMuted),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.streakDays(streak),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.callout.message.isNotEmpty)
            Text(
              summary.callout.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: WeeklyActivityBarsChart(
              values: minutes.take(n).toList(),
              labels: labels.take(n).toList(),
              barColor: primaryColor,
              highlightIndex: hi,
              highlightColor: AppColors.chartHighlight,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.pushNamed(ProgressReportPage.routeName),
              icon: Icon(Icons.insights_outlined, size: 18, color: primaryColor),
              label: Text(
                'Full progress & stats',
                style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.noStudyWeek,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
