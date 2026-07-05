import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/entity/speaking_phase2_entity.dart';
import '../../core/get_it/get_it.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import 'speaking_feedback_page.dart';
import 'speaking_phase2_bloc/speaking_phase2_bloc.dart';
import 'speaking_phase2_bloc/speaking_phase2_event.dart';
import 'speaking_phase2_bloc/speaking_phase2_state.dart';

class SpeakingProgressDashboardPage extends StatelessWidget {
  static const routeName = 'SpeakingProgressDashboardPage';
  static const routePath = '/speaking-progress';

  const SpeakingProgressDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SpeakingPhase2Bloc>()..add(const LoadSpeakingProgressEvent()),
      child: const _SpeakingProgressDashboardView(),
    );
  }
}

class _SpeakingProgressDashboardView extends StatelessWidget {
  const _SpeakingProgressDashboardView();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(
        context,
        title: t.speakingDashboardTitle,
        skill: SkillType.speaking,
      ),
      body: BlocBuilder<SpeakingPhase2Bloc, SpeakingPhase2State>(
        buildWhen: (prev, next) =>
            prev.status != next.status || prev.progress != next.progress,
        builder: (context, state) {
          if (state.status == SpeakingPhase2Status.loading) {
            return Center(child: StudentMobileUi.runnerLoading());
          }
          if (state.status == SpeakingPhase2Status.error) {
            return StudentMobileUi.errorRetry(
              context,
              title: t.speakingErrorTitle,
              message: t.speakingErrorBody,
              onRetry: () => context
                  .read<SpeakingPhase2Bloc>()
                  .add(const LoadSpeakingProgressEvent()),
              retryLabel: t.commonRetry,
            );
          }
          final progress = state.progress;
          if (progress == null || progress.sessions == 0) {
            return StudentMobileUi.emptyState(
              context,
              icon: Icons.insights_outlined,
              title: t.speakingDashboardEmptyTitle,
              body: t.speakingDashboardEmptyBody,
              skill: SkillType.speaking,
            );
          }
          return ListView(
            padding: StudentMobileUi.pagePadding,
            children: [
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.s3,
                mainAxisSpacing: AppSpacing.s3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.45,
                children: [
                  _KpiCard(
                      label: t.speakingDashboardSessions,
                      value: '${progress.sessions}'),
                  _KpiCard(
                      label: t.speakingDashboardMinutes,
                      value: '${progress.minutes}'),
                  _KpiCard(
                      label: t.speakingDashboardAvgBand,
                      value: progress.averageOverall.toStringAsFixed(1)),
                  _KpiCard(
                      label: t.speakingDashboardStreak,
                      value: '${progress.speakingStreak}'),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              _ScoreChart(progress: progress),
              const SizedBox(height: AppSpacing.s4),
              Text(t.speakingDashboardRecent,
                  style: StudentMobileUi.sectionTitle(context)),
              const SizedBox(height: AppSpacing.s3),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: progress.recent.length,
                itemBuilder: (context, index) =>
                    _RecentSessionTile(item: progress.recent[index]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: StudentMobileUi.kpi(context)),
          const SizedBox(height: AppSpacing.s1),
          Text(label, style: StudentMobileUi.caption(context)),
        ],
      ),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  final SpeakingProgressSummaryEntity progress;

  const _ScoreChart({required this.progress});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < progress.overallSeries.length; i++) {
      spots.add(FlSpot(i.toDouble(), progress.overallSeries[i]));
    }
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: SizedBox(
        height: 210,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 9,
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= progress.labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(progress.labels[i],
                        style: StudentMobileUi.caption(context));
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppSkillColors.speaking.color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppSkillColors.speaking.color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSessionTile extends StatelessWidget {
  final SpeakingProgressRecentEntity item;

  const _RecentSessionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppCard(
        variant: AppCardVariant.outline,
        onTap: () => context.pushNamed(
          SpeakingFeedbackPage.routeName,
          extra: SpeakingFeedbackPageArgs.load(item.id),
        ),
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Row(
          children: [
            StudentMobileUi.skillIconBox(Icons.record_voice_over_outlined,
                skill: SkillType.speaking),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child:
                  Text(item.title, style: StudentMobileUi.cardTitle(context)),
            ),
            Text(item.overall.toStringAsFixed(1),
                style: StudentMobileUi.cardTitle(context)
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
