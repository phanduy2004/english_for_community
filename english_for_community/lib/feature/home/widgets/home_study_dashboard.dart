import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entity/progress_summary_entity.dart';
import '../../../core/locale/l10n_context.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/animation/animated_status_container.dart';
import '../../../core/ui/student_mobile_ui.dart';
import '../../../core/ui/widget/app_card.dart';
import '../../../core/ui/widget/app_skeleton.dart';
import '../../progress/bloc/progress_bloc.dart';
import '../../progress/bloc/progress_event.dart';
import '../../progress/bloc/progress_state.dart';
import '../../progress/progress_report_page.dart';
import '../../progress/widgets/weekly_activity_bars_chart.dart';

/// Card preview tiến độ tuần — dùng chung chart với màn Progress.
class HomeStudyDashboard extends StatelessWidget {
  const HomeStudyDashboard({
    super.key,
    required this.streak,
    required this.dailyProgress,
    required this.dailyGoal,
  });

  final int streak;
  final int dailyProgress;
  final int dailyGoal;

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
          body = StudentMobileUi.errorBanner(
            message: context.l10n.couldNotLoadStudyChart,
            onRetry: () =>
                context.read<ProgressBloc>().add(const FetchProgressData(range: 'week')),
            retryLabel: context.l10n.commonRetry,
          );
        } else {
          body = _ChartCard(
            summary: state.summary!,
            streak: streak,
            dailyProgress: dailyProgress,
            dailyGoal: dailyGoal,
          );
        }

        return AnimatedStatusContainer(statusKey: statusKey, child: body);
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.summary,
    required this.streak,
    required this.dailyProgress,
    required this.dailyGoal,
  });

  final ProgressSummaryEntity summary;
  final int streak;
  final int dailyProgress;
  final int dailyGoal;

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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
        color: AppColors.surfaceCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
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
                      Text(
                        context.l10n.weeklyActivity,
                        style: StudentMobileUi.cardTitle(context),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        context.l10n.weeklySummaryLine(_fmtMinutes(totalWeek), dailyProgress, dailyGoal),
                        style: StudentMobileUi.caption(context),
                      ),
                    ],
                  ),
                ),
                if (streak > 0) StudentMobileUi.streakChip(context, streak),
              ],
            ),
            if (dailyGoal > 0) ...[
              const SizedBox(height: AppSpacing.s3),
              StudentMobileUi.skillProgressBar(
                context: context,
                value: dailyGoal > 0 ? dailyProgress / dailyGoal : 0,
                color: AppColors.chartBar,
                height: AppSpacing.s2,
              ),
            ],
            if (summary.callout.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                summary.callout.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: StudentMobileUi.caption(context).copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: AppSpacing.s2),
            SizedBox(
              height: 120,
              child: WeeklyActivityBarsChart(
                values: minutes.take(n).toList(),
                labels: labels.take(n).toList(),
                barColor: AppColors.chartBar,
                highlightIndex: hi,
                highlightColor: AppColors.chartHighlight,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.pushNamed(ProgressReportPage.routeName),
                icon: const Icon(Icons.insights_outlined, size: 16, color: AppColors.accent),
                label: Text(
                  context.l10n.fullProgressStats,
                  style: AppTypography.label(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Text(
        context.l10n.noStudyWeek,
        style: StudentMobileUi.body(context),
      ),
    );
  }
}
