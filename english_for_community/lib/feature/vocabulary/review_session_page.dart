import 'package:flutter/material.dart';
import 'package:english_for_community/core/util/app_haptics.dart';
import 'package:english_for_community/core/ui/motion/celebrate_burst.dart';
import 'package:english_for_community/core/theme/app_motion.dart' as theme_motion;
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/repository/user_vocab_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'bloc_review/review_bloc.dart';
import 'bloc_review/review_event.dart';
import 'bloc_review/review_state.dart';

class ReviewSessionPage extends StatelessWidget {
  const ReviewSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ReviewBloc(userVocabRepository: getIt<UserVocabRepository>())..add(FetchReviewWords()),
      child: const _ReviewSessionView(),
    );
  }
}

class _ReviewSessionView extends StatefulWidget {
  const _ReviewSessionView();
  @override
  State<_ReviewSessionView> createState() => _ReviewSessionViewState();
}

class _ReviewSessionViewState extends State<_ReviewSessionView> {
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  int _getElapsedSeconds() {
    if (_startTime == null) return 0;
    final now = DateTime.now();
    final diff = now.difference(_startTime!).inSeconds;
    _startTime = now;
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final vocab = AppSkillColors.vocabulary;

    return BlocConsumer<ReviewBloc, ReviewState>(
      listener: (context, state) {},
      builder: (context, state) {
        final blockExit = state.status != ReviewStatus.loading &&
            state.status != ReviewStatus.error &&
            state.status != ReviewStatus.complete &&
            state.currentWord != null;

        return StudentMobileUi.runnerPopScope(
          context: context,
          blockExit: blockExit,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: StudentMobileUi.skillAppBar(
              context,
              title: t.vocabReviewSessionTitle,
              skill: SkillType.vocabulary,
            ),
            body: _buildBody(context, state, t, vocab),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReviewState state,
    AppLocalizations t,
    SkillColorSet vocab,
  ) {
    if (state.status == ReviewStatus.loading) {
      return StudentMobileUi.flashcardLoading();
    }
    if (state.status == ReviewStatus.error) {
      final msg = state.errorMessage;
      return StudentMobileUi.errorRetry(
        context,
        message: msg.isEmpty ? t.genericLoadError : msg,
        onRetry: () => context.read<ReviewBloc>().add(FetchReviewWords()),
        retryLabel: t.commonRetry,
      );
    }
    if (state.status == ReviewStatus.complete || state.currentWord == null) {
      return const _CompleteView();
    }

    final word = state.currentWord!;
    final total = state.wordsToReview.length;
    final current = state.currentIndex + 1;
    final progress = current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudentMobileUi.pageHPadding,
            AppSpacing.s4,
            StudentMobileUi.pageHPadding,
            AppSpacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '$current / $total',
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: AppTypography.label(color: vocab.color),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              StudentMobileUi.skillProgressBar(
                context: context,
                value: progress,
                color: vocab.color,
                height: 6,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              StudentMobileUi.pageHPadding,
              AppSpacing.s3,
              StudentMobileUi.pageHPadding,
              AppSpacing.s4,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minH = (constraints.maxHeight * 0.72).clamp(280.0, 420.0);
                return GestureDetector(
                  onTap: () {
                    AppHaptics.select(context);
                    context.read<ReviewBloc>().add(FlipCard());
                  },
                  child: _ReviewFlashcard(
                    word: word.headword,
                    ipa: word.ipa,
                    definition: word.shortDefinition ?? '',
                    isFlipped: state.isFlipped,
                    tapHint: t.tapToSeeMeaning,
                    minHeight: minH,
                  ),
                );
              },
            ),
          ),
        ),
        _buildButtons(context, state, t),
        SizedBox(height: AppSpacing.s5 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, ReviewState state, AppLocalizations t) {
    if (!state.isFlipped) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: StudentMobileUi.pageHPadding),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              AppHaptics.select(context);
              context.read<ReviewBloc>().add(FlipCard());
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(
              t.showAnswerButton,
              style: AppTypography.label(color: AppColors.onPrimary),
            ),
          ),
        ),
      );
    }

    final word = state.currentWord!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StudentMobileUi.pageHPadding),
      child: Row(
        children: [
              Expanded(
                child: _FeedbackBtn(
                  label: t.srsHard,
                  accent: AppColors.danger,
                  onPressed: () {
                    AppHaptics.confirm(context);
                    context.read<ReviewBloc>().add(
                          SubmitFeedback(
                            feedback: 'hard',
                            word: word,
                            duration: _getElapsedSeconds(),
                          ),
                        );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _FeedbackBtn(
                  label: t.srsGood,
                  accent: AppColors.primary,
                  onPressed: () {
                    AppHaptics.confirm(context);
                    context.read<ReviewBloc>().add(
                          SubmitFeedback(
                            feedback: 'good',
                            word: word,
                            duration: _getElapsedSeconds(),
                          ),
                        );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _FeedbackBtn(
                  label: t.srsEasy,
                  accent: AppColors.success,
                  onPressed: () {
                    AppHaptics.confirm(context);
                    context.read<ReviewBloc>().add(
                          SubmitFeedback(
                            feedback: 'easy',
                            word: word,
                            duration: _getElapsedSeconds(),
                          ),
                        );
                  },
                ),
              ),
            ],
          ),
    );
  }
}

/// Flashcard full-width — `05-mobile-screens` §6.3 (tỷ lệ ~ 280×360, căn giữa nội dung).
class _ReviewFlashcard extends StatelessWidget {
  const _ReviewFlashcard({
    required this.word,
    required this.ipa,
    required this.definition,
    required this.isFlipped,
    required this.tapHint,
    required this.minHeight,
  });

  final String word;
  final String? ipa;
  final String definition;
  final bool isFlipped;
  final String tapHint;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final vocab = AppSkillColors.vocabulary;

    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            border: Border.all(color: AppColors.outline),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowCard,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  color: vocab.color,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s6,
                      vertical: AppSpacing.s7,
                    ),
                    child: AnimatedSwitcher(
                      duration: theme_motion.AppMotion.effective(
                        context,
                        theme_motion.AppMotion.page,
                      ),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: isFlipped
                          ? _BackFace(
                              key: const ValueKey('back'),
                              ipa: ipa,
                              definition: definition,
                            )
                          : _FrontFace(
                              key: const ValueKey('front'),
                              word: word,
                              tapHint: tapHint,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({
    super.key,
    required this.word,
    required this.tapHint,
  });

  final String word;
  final String tapHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          word,
          textAlign: TextAlign.center,
          style: AppTypography.kpiValue(web: false).copyWith(
            fontSize: 32,
            height: 1.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: StudentMobileUi.sectionGap),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.outlineMuted),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  tapHint,
                  style: StudentMobileUi.caption(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({
    super.key,
    required this.ipa,
    required this.definition,
  });

  final String? ipa;
  final String definition;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ipa != null && ipa!.isNotEmpty) ...[
          Text(
            '/$ipa/',
            textAlign: TextAlign.center,
            style: StudentMobileUi.body(context).copyWith(
              fontFamily: 'NotoSans',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s5),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.outlineMuted),
          ),
          child: Text(
            definition.isEmpty ? '—' : definition,
            textAlign: TextAlign.center,
            style: StudentMobileUi.bodyLg(context),
          ),
        ),
      ],
    );
  }
}

class _FeedbackBtn extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onPressed;

  const _FeedbackBtn({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.45)),
          backgroundColor: accent.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTypography.label(color: accent),
        ),
      ),
    );
  }
}

class _CompleteView extends StatefulWidget {
  const _CompleteView();

  @override
  State<_CompleteView> createState() => _CompleteViewState();
}

class _CompleteViewState extends State<_CompleteView> {
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _celebrate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return CelebrateBurst(
      trigger: _celebrate,
      child: StudentMobileUi.emptyState(
        context,
        icon: Icons.check_circle_outline_rounded,
        title: t.vocabSessionCompleteTitle,
        body: t.vocabSessionCompleteBody,
        ctaLabel: t.backToHome,
        onCta: () => Navigator.of(context).pop(),
        skill: SkillType.vocabulary,
      ),
    );
  }
}