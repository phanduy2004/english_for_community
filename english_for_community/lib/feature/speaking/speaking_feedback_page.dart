import 'package:english_for_community/core/entity/speaking_conversation_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/user_vocab_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/speaking/free_speaking_page.dart';
import 'package:english_for_community/feature/speaking/speaking_feedback_bloc/speaking_feedback_bloc.dart';
import 'package:english_for_community/feature/speaking/speaking_feedback_bloc/speaking_feedback_event.dart';
import 'package:english_for_community/feature/speaking/speaking_feedback_bloc/speaking_feedback_state.dart';
import 'package:english_for_community/feature/writing/widgets/interactive_diff_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

class _SpeakingFeedbackHistoryView extends StatelessWidget {
  const _SpeakingFeedbackHistoryView();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(
        context,
        title: t.speakingFbHistoryTitle,
        skill: SkillType.speaking,
      ),
      body: BlocBuilder<SpeakingFeedbackBloc, SpeakingFeedbackState>(
        builder: (context, state) {
          if (state.status == SpeakingFeedbackStatus.loading) {
            return Center(child: StudentMobileUi.runnerLoading());
          }
          if (state.status == SpeakingFeedbackStatus.error) {
            return Padding(
              padding: StudentMobileUi.pagePadding,
              child: StudentMobileUi.errorBanner(
                message: state.errorMessage ?? t.loadDataFailed,
                onRetry: () => context
                    .read<SpeakingFeedbackBloc>()
                    .add(const LoadConversationHistoryEvent()),
                retryLabel: t.commonRetry,
              ),
            );
          }
          if (state.history.isEmpty) {
            return StudentMobileUi.emptyState(
              context,
              icon: Icons.history_rounded,
              title: t.speakingFbHistoryEmptyTitle,
              body: t.speakingFbHistoryEmptyBody,
              skill: SkillType.speaking,
            );
          }
          return ListView.separated(
            padding: StudentMobileUi.pagePadding,
            itemCount: state.history.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
            itemBuilder: (context, index) {
              final item = state.history[index];
              final date =
                  item.createdAt?.toLocal().toString().split('.').first ?? '';
              return AppCard(
                variant: AppCardVariant.outline,
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    date,
                    style: StudentMobileUi.cardTitle(context),
                  ),
                  subtitle: Text(
                    t.speakingFbHistoryMeta(
                      item.durationSeconds,
                      item.turnCount,
                      item.cefr ?? '-',
                    ),
                    style: StudentMobileUi.body(context)
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: Text(
                    item.overall?.toStringAsFixed(1) ?? '-',
                    style: StudentMobileUi.sectionTitle(context)
                        .copyWith(color: AppColors.primary),
                  ),
                  onTap: () => context.pushNamed(
                    SpeakingFeedbackPage.routeName,
                    extra: SpeakingFeedbackPageArgs.load(item.id),
                  ),
                ),
              );
            },
          );
        },
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
      (failure) =>
          AppFeedback.error(context, context.l10n.speakingFbSaveError),
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
                        style: StudentMobileUi.body(context)
                            .copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
