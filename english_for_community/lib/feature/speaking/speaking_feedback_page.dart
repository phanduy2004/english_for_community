import 'package:english_for_community/core/entity/speaking_conversation_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/user_vocab_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_score_scale.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/speaking/free_speaking_page.dart';
import 'package:english_for_community/feature/speaking/speaking_progress_dashboard_page.dart';
import 'package:english_for_community/feature/speaking/speaking_feedback_bloc/speaking_feedback_bloc.dart';
import 'package:english_for_community/feature/speaking/speaking_feedback_bloc/speaking_feedback_event.dart';
import 'package:english_for_community/feature/speaking/speaking_feedback_bloc/speaking_feedback_state.dart';
import 'package:english_for_community/feature/writing/widgets/interactive_diff_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SpeakingFeedbackPageArgs {
  final List<SpeakingTurnEntity>? turns;
  final int? durationSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? level;
  final String? scenarioId;
  final String? conversationId;

  const SpeakingFeedbackPageArgs.evaluate({
    required this.turns,
    required this.durationSeconds,
    this.startedAt,
    this.endedAt,
    this.level,
    this.scenarioId,
  }) : conversationId = null;

  const SpeakingFeedbackPageArgs.load(this.conversationId)
      : turns = null,
        durationSeconds = null,
        startedAt = null,
        endedAt = null,
        level = null,
        scenarioId = null;
}

class SpeakingFeedbackPage extends StatelessWidget {
  static const routeName = 'SpeakingFeedbackPage';
  static const routePath = '/speaking-feedback';

  final SpeakingFeedbackPageArgs args;

  const SpeakingFeedbackPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = getIt<SpeakingFeedbackBloc>();
        final id = args.conversationId;
        if (id != null && id.isNotEmpty) {
          bloc.add(LoadConversationEvent(id));
        } else {
          bloc.add(EvaluateConversationEvent(
            turns: args.turns ?? const [],
            durationSeconds: args.durationSeconds ?? 0,
            startedAt: args.startedAt,
            endedAt: args.endedAt,
            level: args.level,
            scenarioId: args.scenarioId,
          ));
        }
        return bloc;
      },
      child: _SpeakingFeedbackView(args: args),
    );
  }
}

class _SpeakingFeedbackView extends StatelessWidget {
  final SpeakingFeedbackPageArgs args;

  const _SpeakingFeedbackView({required this.args});

  void _retry(BuildContext context) {
    context.read<SpeakingFeedbackBloc>().add(EvaluateConversationEvent(
          turns: args.turns ?? const [],
          durationSeconds: args.durationSeconds ?? 0,
          startedAt: args.startedAt,
          endedAt: args.endedAt,
          level: args.level,
          scenarioId: args.scenarioId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocBuilder<SpeakingFeedbackBloc, SpeakingFeedbackState>(
      builder: (context, state) {
        final conversation = state.conversation;
        final fb = conversation?.feedback;
        final isLoading = state.status == SpeakingFeedbackStatus.evaluating ||
            state.status == SpeakingFeedbackStatus.loading;

        if (isLoading || fb == null) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: StudentMobileUi.skillAppBar(
              context,
              title: t.speakingFbTitle,
              skill: SkillType.speaking,
            ),
            body: state.status == SpeakingFeedbackStatus.error
                ? StudentMobileUi.errorRetry(
                    context,
                    title: t.speakingFbErrorTitle,
                    message: t.speakingFbErrorBody,
                    onRetry: args.conversationId == null
                        ? () => _retry(context)
                        : () => context.read<SpeakingFeedbackBloc>().add(
                              LoadConversationEvent(args.conversationId!),
                            ),
                    retryLabel: t.speakingFbRetry,
                  )
                : Center(
                    child: Padding(
                      padding: StudentMobileUi.pagePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StudentMobileUi.runnerLoading(),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            t.speakingFbAnalyzing,
                            textAlign: TextAlign.center,
                            style: StudentMobileUi.body(context)
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              toolbarHeight: StudentMobileUi.appBarHeight,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              title: Text(
                t.speakingFbTitle,
                style: StudentMobileUi.sectionTitle(context),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.outline)),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: StudentMobileUi.cardTitle(context),
                    tabs: [
                      Tab(text: t.speakingFbTabOverview),
                      Tab(text: t.speakingFbTabDetails),
                      Tab(text: t.speakingFbTabCorrections),
                      Tab(text: t.speakingFbTabSamples),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(feedback: fb),
                _DetailsTab(feedback: fb),
                _CorrectionsTab(feedback: fb),
                _SamplesTab(feedback: fb),
              ],
            ),
            bottomNavigationBar: _FeedbackFooter(feedback: fb),
          ),
        );
      },
    );
  }
}

class SpeakingFeedbackHistoryPage extends StatelessWidget {
  static const routeName = 'SpeakingFeedbackHistoryPage';
  static const routePath = '/speaking-feedback-history';

  const SpeakingFeedbackHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SpeakingFeedbackBloc>()
        ..add(const LoadConversationHistoryEvent()),
      child: const _SpeakingFeedbackHistoryView(),
    );
  }
}

enum _HistorySort { newest, oldest, highest, longest }

const List<String> _cefrOrder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

class _SpeakingFeedbackHistoryView extends StatefulWidget {
  const _SpeakingFeedbackHistoryView();

  @override
  State<_SpeakingFeedbackHistoryView> createState() =>
      _SpeakingFeedbackHistoryViewState();
}

class _SpeakingFeedbackHistoryViewState
    extends State<_SpeakingFeedbackHistoryView> {
  String? _cefr; // null = all levels
  _HistorySort _sort = _HistorySort.newest;

  Future<void> _refresh() async {
    final bloc = context.read<SpeakingFeedbackBloc>();
    bloc.add(const LoadConversationHistoryEvent());
    await bloc.stream.firstWhere(
      (s) =>
          s.status == SpeakingFeedbackStatus.historyLoaded ||
          s.status == SpeakingFeedbackStatus.error,
    );
  }

  List<SpeakingConversationSummaryEntity> _visible(
    List<SpeakingConversationSummaryEntity> items,
  ) {
    final list = _cefr == null
        ? List<SpeakingConversationSummaryEntity>.from(items)
        : items.where((e) => (e.cefr ?? '') == _cefr).toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    switch (_sort) {
      case _HistorySort.newest:
        list.sort(
            (a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
      case _HistorySort.oldest:
        list.sort(
            (a, b) => (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch));
      case _HistorySort.highest:
        list.sort((a, b) => (b.overall ?? 0).compareTo(a.overall ?? 0));
      case _HistorySort.longest:
        list.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(
        context,
        title: t.speakingFbHistoryTitle,
        skill: SkillType.speaking,
        actions: [
          StudentMobileUi.headerIconButton(
            context: context,
            icon: Icons.insights_outlined,
            tooltip: t.speakingHistoryViewProgress,
            onPressed: () =>
                context.pushNamed(SpeakingProgressDashboardPage.routeName),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: BlocBuilder<SpeakingFeedbackBloc, SpeakingFeedbackState>(
        builder: (context, state) {
          if (state.status == SpeakingFeedbackStatus.loading) {
            return StudentMobileUi.listLoading();
          }
          if (state.status == SpeakingFeedbackStatus.error) {
            return StudentMobileUi.errorRetry(
              context,
              title: t.speakingErrorTitle,
              message: state.errorMessage ?? t.speakingErrorBody,
              onRetry: () => context
                  .read<SpeakingFeedbackBloc>()
                  .add(const LoadConversationHistoryEvent()),
              retryLabel: t.commonRetry,
            );
          }
          final all = state.history;
          if (all.isEmpty) {
            return StudentMobileUi.emptyState(
              context,
              icon: Icons.history_rounded,
              title: t.speakingFbHistoryEmptyTitle,
              body: t.speakingFbHistoryEmptyBody,
              skill: SkillType.speaking,
              ctaLabel: t.speakingHistoryStartCta,
              onCta: () => context.go(FreeSpeakingPage.routePath),
            );
          }
          final levels = _cefrLevels(all);
          final visible = _visible(all);
          return RefreshIndicator(
            color: AppSkillColors.speaking.color,
            onRefresh: _refresh,
            child: ListView(
              padding: StudentMobileUi.pagePadding,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(t.speakingHistorySummaryTitle,
                    style: StudentMobileUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s3),
                _HistoryKpiRow(items: all),
                if (all.where((e) => e.overall != null).length >= 3) ...[
                  const SizedBox(height: AppSpacing.s3),
                  _HistorySparkline(items: all),
                ],
                const SizedBox(height: AppSpacing.s5),
                if (levels.length > 1) ...[
                  StudentMobileUi.filterRow(
                    labels: [t.speakingHistoryFilterAll, ...levels],
                    selectedIndex:
                        _cefr == null ? 0 : levels.indexOf(_cefr!) + 1,
                    onSelected: (i) =>
                        setState(() => _cefr = i == 0 ? null : levels[i - 1]),
                    skill: SkillType.speaking,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.speakingHistorySessionsCount(visible.length),
                        style: StudentMobileUi.sectionTitle(context),
                      ),
                    ),
                    _SortButton(
                      value: _sort,
                      onChanged: (v) => setState(() => _sort = v),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                if (visible.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                    child: Text(
                      t.speakingHistoryFilterEmpty,
                      textAlign: TextAlign.center,
                      style: StudentMobileUi.body(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...visible.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                      child: _HistorySessionCard(item: item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

List<String> _cefrLevels(List<SpeakingConversationSummaryEntity> items) {
  final levels = items
      .map((e) => e.cefr)
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();
  int rank(String l) {
    final i = _cefrOrder.indexOf(l);
    return i < 0 ? 99 : i;
  }

  levels.sort((a, b) => rank(a).compareTo(rank(b)));
  return levels;
}

String _fmtDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final r = seconds % 60;
  return r == 0 ? '${m}m' : '${m}m ${r}s';
}

/// KPI row (sessions / avg band / best band) computed from the loaded history.
class _HistoryKpiRow extends StatelessWidget {
  final List<SpeakingConversationSummaryEntity> items;

  const _HistoryKpiRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final scores =
        items.map((e) => e.overall).whereType<double>().toList(growable: false);
    final avg =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final best = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        Expanded(
          child: StudentMobileUi.statCard(
            context: context,
            icon: Icons.forum_outlined,
            value: '${items.length}',
            label: t.speakingHistoryStatSessions,
            compact: true,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: StudentMobileUi.statCard(
            context: context,
            icon: Icons.equalizer_rounded,
            value: avg.toStringAsFixed(1),
            label: t.speakingHistoryStatAvg,
            compact: true,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: StudentMobileUi.statCard(
            context: context,
            icon: Icons.emoji_events_outlined,
            value: best.toStringAsFixed(1),
            label: t.speakingHistoryStatBest,
            compact: true,
            iconColor: AppColors.accent,
            iconBg: AppColors.accentTint,
          ),
        ),
      ],
    );
  }
}

/// Compact band-score sparkline (chronological) — deep dive lives on the
/// progress dashboard.
class _HistorySparkline extends StatelessWidget {
  final List<SpeakingConversationSummaryEntity> items;

  const _HistorySparkline({required this.items});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final scored = items.where((e) => e.overall != null).toList()
      ..sort((a, b) => (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch));
    final spots = <FlSpot>[
      for (var i = 0; i < scored.length; i++)
        FlSpot(i.toDouble(), scored[i].overall!),
    ];
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.speakingHistoryTrend,
              style: StudentMobileUi.cardTitle(context)),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            height: 88,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 9,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppSkillColors.speaking.color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          AppSkillColors.speaking.color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular band-score badge, colour-coded by [AppScoreScale].
class _ScoreBadge extends StatelessWidget {
  final double? score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final s = score;
    final color = s == null ? AppColors.textMuted : AppScoreScale.forScore10(s);
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        s == null ? '–' : s.toStringAsFixed(1),
        style: StudentMobileUi.cardTitle(context).copyWith(color: color),
      ),
    );
  }
}

class _CefrChip extends StatelessWidget {
  final String label;

  const _CefrChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 1),
      decoration: BoxDecoration(
        color: AppSkillColors.speaking.tint,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppSkillColors.speaking.color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: StudentMobileUi.caption(context).copyWith(
          color: AppSkillColors.speaking.dark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  final SpeakingConversationSummaryEntity item;

  const _HistorySessionCard({required this.item});

  String _meta(BuildContext context) {
    final parts = <String>[];
    final d = item.createdAt?.toLocal();
    if (d != null) parts.add(DateFormat('d MMM · HH:mm').format(d));
    parts.add(_fmtDuration(item.durationSeconds));
    parts.add(context.l10n.speakingHistoryTurns(item.turnCount));
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final title = item.title.trim().isNotEmpty
        ? item.title
        : t.speakingHistoryDefaultTitle;
    return StudentMobileUi.skillAccentCard(
      skill: SkillType.speaking,
      padding: const EdgeInsets.all(AppSpacing.s4),
      onTap: () => context.pushNamed(
        SpeakingFeedbackPage.routeName,
        extra: SpeakingFeedbackPageArgs.load(item.id),
      ),
      child: Row(
        children: [
          _ScoreBadge(score: item.overall),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudentMobileUi.cardTitle(context),
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  children: [
                    if ((item.cefr ?? '').isNotEmpty) ...[
                      _CefrChip(label: item.cefr!),
                      const SizedBox(width: AppSpacing.s2),
                    ],
                    Expanded(
                      child: Text(
                        _meta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StudentMobileUi.caption(context)
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final _HistorySort value;
  final ValueChanged<_HistorySort> onChanged;

  const _SortButton({required this.value, required this.onChanged});

  String _label(BuildContext context, _HistorySort sort) {
    final t = context.l10n;
    switch (sort) {
      case _HistorySort.newest:
        return t.speakingHistorySortNewest;
      case _HistorySort.oldest:
        return t.speakingHistorySortOldest;
      case _HistorySort.highest:
        return t.speakingHistorySortHighest;
      case _HistorySort.longest:
        return t.speakingHistorySortLongest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HistorySort>(
      initialValue: value,
      tooltip: context.l10n.speakingHistorySort,
      position: PopupMenuPosition.under,
      onSelected: onChanged,
      itemBuilder: (context) => _HistorySort.values
          .map((s) => PopupMenuItem<_HistorySort>(
                value: s,
                child: Text(_label(context, s)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.s2),
            Text(_label(context, value),
                style: StudentMobileUi.caption(context)),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final SpeakingFeedbackEntity feedback;

  const _OverviewTab({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return ListView(
      padding: StudentMobileUi.pagePadding,
      children: [
        _ShadcnCard(
          child: Column(
            children: [
              Text(t.speakingFbCefr,
                  style: StudentMobileUi.body(context)
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.s2),
              Text(
                feedback.cefr,
                style: StudentMobileUi.greeting(context)
                    .copyWith(fontSize: 44, height: 1),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                t.speakingFbOverall(feedback.overall.toStringAsFixed(1)),
                style: StudentMobileUi.cardTitle(context),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                feedback.summary,
                textAlign: TextAlign.center,
                style: StudentMobileUi.body(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _ShadcnCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreRow(
                label: t.speakingFbCriterionFc,
                score: feedback.fc,
                trend: feedback.trends?.fc,
              ),
              const Divider(height: 24, color: AppColors.outlineMuted),
              _ScoreRow(
                label: t.speakingFbCriterionLr,
                score: feedback.lr,
                trend: feedback.trends?.lr,
              ),
              const Divider(height: 24, color: AppColors.outlineMuted),
              _ScoreRow(
                label: t.speakingFbCriterionGra,
                score: feedback.gra,
                trend: feedback.trends?.gra,
              ),
              const Divider(height: 24, color: AppColors.outlineMuted),
              _ScoreRow(
                label: t.speakingFbCriterionIa,
                score: feedback.ia,
                trend: feedback.trends?.ia,
              ),
              if (feedback.taskAchievement != null) ...[
                const Divider(height: 24, color: AppColors.outlineMuted),
                _ScoreRow(
                  label: t.speakingFbTaskAchievement,
                  score: feedback.taskAchievement,
                ),
                if (feedback.taskNote.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    feedback.taskNote,
                    style: StudentMobileUi.body(context)
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
              const Divider(height: 24, color: AppColors.outlineMuted),
              Text(
                t.speakingFbPronunciationSoon,
                style: StudentMobileUi.body(context)
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _StatsWrap(stats: feedback.stats),
        if (feedback.strengths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          _ShadcnCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.speakingFbStrengths,
                    style: StudentMobileUi.cardTitle(context)),
                const SizedBox(height: AppSpacing.s3),
                _BulletedList(items: feedback.strengths),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final SpeakingFeedbackEntity feedback;

  const _DetailsTab({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return ListView(
      padding: StudentMobileUi.pagePadding,
      children: [
        _CriteriaCard(
          label: t.speakingFbCriterionFc,
          score: feedback.fc,
          bullets: feedback.fcBullets,
          note: feedback.fcNote,
        ),
        const SizedBox(height: AppSpacing.s4),
        _CriteriaCard(
          label: t.speakingFbCriterionLr,
          score: feedback.lr,
          bullets: feedback.lrBullets,
          note: feedback.lrNote,
        ),
        const SizedBox(height: AppSpacing.s4),
        _CriteriaCard(
          label: t.speakingFbCriterionGra,
          score: feedback.gra,
          bullets: feedback.graBullets,
          note: feedback.graNote,
        ),
        const SizedBox(height: AppSpacing.s4),
        _CriteriaCard(
          label: t.speakingFbCriterionIa,
          score: feedback.ia,
          bullets: feedback.iaBullets,
          note: feedback.iaNote,
        ),
      ],
    );
  }
}

class _CorrectionsTab extends StatelessWidget {
  final SpeakingFeedbackEntity feedback;

  const _CorrectionsTab({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return ListView(
      padding: StudentMobileUi.pagePadding,
      children: [
        if (feedback.improvements.isNotEmpty) ...[
          _SectionTitle(title: t.speakingFbImprovements),
          const SizedBox(height: AppSpacing.s3),
          ...feedback.improvements.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: _ImprovementCard(item: item),
              )),
        ],
        if (feedback.corrections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          _SectionTitle(title: t.speakingFbCorrections),
          const SizedBox(height: AppSpacing.s3),
          ...feedback.corrections.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: _CorrectionCard(item: item),
              )),
        ],
        if (feedback.vocabUpgrades.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          _SectionTitle(title: t.speakingFbVocabUpgrades),
          const SizedBox(height: AppSpacing.s3),
          ...feedback.vocabUpgrades.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: _VocabUpgradeCard(item: item),
              )),
        ],
      ],
    );
  }
}

class _SamplesTab extends StatelessWidget {
  final SpeakingFeedbackEntity feedback;

  const _SamplesTab({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (feedback.modelAnswers.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.forum_outlined,
        title: t.speakingFbSamplesEmptyTitle,
        body: t.speakingFbSamplesEmptyBody,
        skill: SkillType.speaking,
      );
    }
    return ListView(
      padding: StudentMobileUi.pagePadding,
      children: [
        _SectionTitle(title: t.speakingFbModelAnswers),
        const SizedBox(height: AppSpacing.s3),
        ...feedback.modelAnswers.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: _ModelAnswerCard(item: item),
            )),
      ],
    );
  }
}

class _FeedbackFooter extends StatelessWidget {
  final SpeakingFeedbackEntity feedback;

  const _FeedbackFooter({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          AppSpacing.s4,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feedback.nextSteps.isNotEmpty) ...[
              Text(t.speakingFbNextSteps,
                  style: StudentMobileUi.cardTitle(context)),
              const SizedBox(height: AppSpacing.s2),
              Text(
                feedback.nextSteps.take(2).join('  '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: StudentMobileUi.body(context)
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s3),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      t.speakingFbBack,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go(FreeSpeakingPage.routePath),
                    icon: const Icon(Icons.mic_rounded, size: 18),
                    label: Text(
                      t.speakingFbSpeakMore,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsWrap extends StatelessWidget {
  final SpeakingStatsEntity? stats;

  const _StatsWrap({required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final s = stats ?? const SpeakingStatsEntity();
    final items = [
      (Icons.timer_outlined, t.speakingFbStatDuration(s.durationSec)),
      (Icons.record_voice_over_outlined, t.speakingFbStatWords(s.words)),
      (Icons.bolt_outlined, t.speakingFbStatWpm(s.wpm.toStringAsFixed(1))),
      (Icons.more_horiz_rounded, t.speakingFbStatFiller(s.fillerCount)),
      (Icons.help_outline_rounded, t.speakingFbStatQuestions(s.questionCount)),
    ];
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$1, size: 15, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.s2),
                    Text(item.$2, style: StudentMobileUi.body(context)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  final SpeakingImprovementEntity item;

  const _ImprovementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.issue, style: StudentMobileUi.cardTitle(context)),
          const SizedBox(height: AppSpacing.s3),
          InteractiveDiffText(
            text: '{{${item.before}||${item.after}||${item.explain}}}',
            originalText: item.before,
          ),
          if (item.explain.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Text(
              item.explain,
              style: StudentMobileUi.body(context)
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  final SpeakingCorrectionEntity item;

  const _CorrectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.type.toUpperCase(),
              style: StudentMobileUi.cardTitle(context)),
          const SizedBox(height: AppSpacing.s3),
          InteractiveDiffText(
            text: '{{${item.before}||${item.after}||${item.reason}}}',
            originalText: item.before,
          ),
        ],
      ),
    );
  }
}

class _VocabUpgradeCard extends StatefulWidget {
  final SpeakingVocabUpgradeEntity item;

  const _VocabUpgradeCard({required this.item});

  @override
  State<_VocabUpgradeCard> createState() => _VocabUpgradeCardState();
}

class _VocabUpgradeCardState extends State<_VocabUpgradeCard> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saving || _saved || widget.item.better.trim().isEmpty) return;
    setState(() => _saving = true);
    final result = await getIt<UserVocabRepository>().saveRawWord(
      headword: widget.item.better.trim(),
      shortDefinition:
          widget.item.note.trim().isEmpty ? null : widget.item.note,
    );
    if (!mounted) return;
    result.fold(
      (failure) => AppFeedback.error(context, context.l10n.speakingFbSaveError),
      (_) {
        setState(() => _saved = true);
        AppFeedback.success(context, context.l10n.speakingFbSaved);
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${widget.item.said}  '),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.arrow_forward_rounded, size: 16),
                ),
                TextSpan(
                  text: '  ${widget.item.better}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: StudentMobileUi.cardTitle(context),
          ),
          if (widget.item.note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              widget.item.note,
              style: StudentMobileUi.body(context)
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton.icon(
            onPressed: _saved ? null : _save,
            icon: Icon(
                _saved ? Icons.check_rounded : Icons.bookmark_add_outlined),
            label: Text(_saved ? t.speakingFbSaved : t.speakingFbSaveWord),
          ),
        ],
      ),
    );
  }
}

class _ModelAnswerCard extends StatelessWidget {
  final SpeakingModelAnswerEntity item;

  const _ModelAnswerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.context.isNotEmpty)
            Text(item.context, style: StudentMobileUi.cardTitle(context)),
          const SizedBox(height: AppSpacing.s3),
          _QuoteBlock(label: t.speakingFbYourTurn, text: item.yourTurn),
          const SizedBox(height: AppSpacing.s3),
          _QuoteBlock(label: t.speakingFbModelTurn, text: item.modelTurn),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  final String label;
  final String text;

  const _QuoteBlock({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: StudentMobileUi.body(context)
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.s2),
          Text(text, style: StudentMobileUi.body(context)),
        ],
      ),
    );
  }
}

class _ShadcnCard extends StatelessWidget {
  final Widget child;

  const _ShadcnCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) =>
      Text(title, style: StudentMobileUi.sectionTitle(context));
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final num? score;
  final double? trend;

  const _ScoreRow({required this.label, required this.score, this.trend});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: StudentMobileUi.body(context)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trend != null && trend != 0) ...[
              Icon(
                trend! > 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color: trend! > 0 ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.s1),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.outlineMuted,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                score?.toStringAsFixed(1) ?? '-',
                style: StudentMobileUi.cardTitle(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CriteriaCard extends StatelessWidget {
  final String label;
  final num? score;
  final List<String> bullets;
  final String note;

  const _CriteriaCard({
    required this.label,
    required this.score,
    required this.bullets,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return _ShadcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScoreRow(label: label, score: score),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            _BulletedList(items: bullets),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                note,
                style: StudentMobileUi.body(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BulletedList extends StatelessWidget {
  final List<String> items;

  const _BulletedList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•',
                        style: TextStyle(
                            color: AppColors.textSecondary, height: 1.4)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style:
                            StudentMobileUi.body(context).copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
