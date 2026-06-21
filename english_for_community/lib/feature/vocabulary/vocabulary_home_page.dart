import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:english_for_community/core/entity/user_word_entity.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_bloc.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_event.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_state.dart';

import '../../core/get_it/get_it.dart';
import '../../core/repository/dictionary_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import 'vocabulary_tutorial_dialog.dart';

class VocabularyHomePage extends StatefulWidget {
  final int? initialIndex;
  const VocabularyHomePage({super.key, this.initialIndex});

  @override
  State<VocabularyHomePage> createState() => _VocabularyHomePageState();
}

class _VocabularyHomePageState extends State<VocabularyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final VocabularyBloc _vocabularyBloc;
  late final DictionaryRepository _dictionaryRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialIndex != null) {
      _tabController.index = widget.initialIndex!;
    }
    _vocabularyBloc = getIt<VocabularyBloc>();
    _dictionaryRepository = getIt<DictionaryRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _vocabularyBloc.add(const FetchVocabularyData());
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => const VocabularyTutorialDialog(),
    );
  }

  Future<void> _navigateToDetail(String headword) async {
    try {
      final result = await _dictionaryRepository.searchWord(headword, limit: 1);
      result.fold(
        (failure) {
          AppFeedback.error(context, context.l10n.vocabErrorWithMessage(failure.message));
        },
        (entries) {
          if (entries.isNotEmpty && entries.first.headword == headword) {
            if (mounted) {
              context
                  .pushNamed(kDictDetailRouteName, extra: entries.first)
                  .then((_) => _loadData());
            }
          } else {
            AppFeedback.error(context, context.l10n.vocabNoDetailsForWord(headword));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, context.l10n.vocabErrorWithMessage(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final vocabAccent = AppSkillColors.of(SkillType.vocabulary).color;

    return BlocProvider.value(
      value: _vocabularyBloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          toolbarHeight: StudentMobileUi.appBarHeight,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            t.vocabularyScreenTitle,
            style: StudentMobileUi.sectionTitle(context),
          ),
          actions: [
            StudentMobileUi.headerIconButton(
              context: context,
              icon: Icons.help_outline_rounded,
              tooltip: t.vocabTutorialTooltip,
              onPressed: _showTutorial,
            ),
            Padding(
              padding: const EdgeInsets.only(right: StudentMobileUi.pageHPadding),
              child: StudentMobileUi.headerIconButton(
                context: context,
                icon: Icons.search_rounded,
                tooltip: t.vocabSearchDictionaryTooltip,
                onPressed: () =>
                    context.pushNamed(kDictDemoRouteName).then((_) => _loadData()),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 2,
                  color: vocabAccent.withValues(alpha: 0.55),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.outline)),
                    color: AppColors.surfaceCard,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: vocabAccent,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: AppTypography.label(),
                    tabs: [
                      Tab(text: t.vocabTabRecently),
                      Tab(text: t.vocabTabLearning),
                      Tab(text: t.vocabTabSaved),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<VocabularyBloc, VocabularyState>(
          builder: (context, state) {
            if (state.status == VocabularyStatus.loading) {
              return StudentMobileUi.listLoading();
            }
            if (state.status == VocabularyStatus.error) {
              return Padding(
                padding: StudentMobileUi.pagePadding,
                child: StudentMobileUi.errorBanner(
                  message: state.errorMessage ?? t.vocabUnknownError,
                  onRetry: _loadData,
                  retryLabel: t.commonRetry,
                ),
              );
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _RecentTab(
                  words: state.recentWords,
                  onTap: _navigateToDetail,
                  onLearn: (w) =>
                      context.read<VocabularyBloc>().add(StartLearningWordEvent(w)),
                ),
                _LearningTab(words: state.learningWords, onTap: _navigateToDetail),
                _SavedTab(
                  words: state.savedWords,
                  onTap: _navigateToDetail,
                  onLearn: (w) =>
                      context.read<VocabularyBloc>().add(StartLearningWordEvent(w)),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.pushNamed(kReviewSessionRouteName),
          backgroundColor: AppSkillColors.vocabulary.color,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          icon: const Icon(Icons.play_lesson_rounded),
          label: Text(
            t.vocabReviewNowFab,
            style: AppTypography.label(color: AppColors.textInverse),
          ),
        ),
      ),
    );
  }
}

class _RecentTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  final Function(UserWordEntity) onLearn;
  const _RecentTab({
    required this.words,
    required this.onTap,
    required this.onLearn,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (words.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.history_rounded,
        title: t.vocabNoRecentWords,
        body: t.vocabSearchDictionaryTooltip,
        skill: SkillType.vocabulary,
      );
    }
    return ListView.separated(
      padding: StudentMobileUi.pagePadding,
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: StudentMobileUi.cardGap),
      itemBuilder: (context, index) {
        final word = words[index];
        final isLearning = word.status == 'learning';
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true,
          action: _ActionButton(
            icon: isLearning ? Icons.check_circle_rounded : Icons.school_rounded,
            color: isLearning ? AppColors.success : AppColors.textSecondary,
            bgColor: isLearning ? AppColors.successBg : AppColors.surfaceSubtle,
            onPressed: isLearning ? null : () => onLearn(word),
          ),
        );
      },
    );
  }
}

class _LearningTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  const _LearningTab({required this.words, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (words.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.school_rounded,
        title: t.vocabLearningEmpty,
        body: t.vocabReviewNowFab,
        skill: SkillType.vocabulary,
      );
    }
    return ListView.separated(
      padding: StudentMobileUi.pagePadding,
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: StudentMobileUi.cardGap),
      itemBuilder: (context, index) {
        final word = words[index];
        final isDue = word.nextReviewDate.isBefore(DateTime.now());
        final nextReviewStr =
            '${word.nextReviewDate.day}/${word.nextReviewDate.month}';

        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: false,
          leadingIcon: Icons.school_rounded,
          customSubtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isDue ? AppColors.dangerBg : AppColors.successBg,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: isDue
                        ? AppColors.danger.withValues(alpha: 0.35)
                        : AppColors.success.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDue ? Icons.access_time_filled : Icons.check_circle,
                      size: 12,
                      color: isDue ? AppColors.danger : AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      isDue
                          ? t.vocabReviewNowBadge
                          : t.vocabReviewOnDate(nextReviewStr),
                      style: AppTypography.label(
                        color: isDue ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Text(
                t.vocabLevelShort(word.learningLevel),
                style: StudentMobileUi.caption(context),
              ),
            ],
          ),
          action: isDue
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _SavedTab extends StatelessWidget {
  final List<UserWordEntity> words;
  final Function(String) onTap;
  final Function(UserWordEntity) onLearn;
  const _SavedTab({
    required this.words,
    required this.onTap,
    required this.onLearn,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (words.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.bookmark_rounded,
        title: t.vocabSavedEmpty,
        body: t.vocabSearchDictionaryTooltip,
        skill: SkillType.vocabulary,
      );
    }
    return ListView.separated(
      padding: StudentMobileUi.pagePadding,
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: StudentMobileUi.cardGap),
      itemBuilder: (context, index) {
        final word = words[index];
        final isLearning = word.status == 'learning';
        return _WordCard(
          word: word,
          onTap: () => onTap(word.headword),
          showMeaning: true,
          leadingIcon: Icons.bookmark_rounded,
          action: _ActionButton(
            icon: isLearning ? Icons.check_circle_rounded : Icons.school_rounded,
            color: isLearning ? AppColors.success : AppColors.textSecondary,
            bgColor: isLearning ? AppColors.successBg : AppColors.surfaceSubtle,
            onPressed: isLearning ? null : () => onLearn(word),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onPressed;
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final UserWordEntity word;
  final VoidCallback onTap;
  final bool showMeaning;
  final Widget? action;
  final IconData? leadingIcon;
  final Widget? customSubtitle;

  const _WordCard({
    required this.word,
    required this.onTap,
    this.showMeaning = true,
    this.action,
    this.leadingIcon,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return StudentMobileUi.skillAccentCard(
      skill: SkillType.vocabulary,
      onTap: onTap,
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            StudentMobileUi.skillIconBox(
              leadingIcon!,
              size: 36,
              skill: SkillType.vocabulary,
            ),
            const SizedBox(width: AppSpacing.s4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: word.headword,
                        style: StudentMobileUi.cardTitle(context),
                      ),
                      if (word.ipa != null && word.ipa!.isNotEmpty)
                        TextSpan(
                          text: ' /${word.ipa}/',
                          style: StudentMobileUi.body(context).copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                if (customSubtitle != null)
                  customSubtitle!
                else if (showMeaning)
                  Text(
                    word.shortDefinition ?? t.wordNoDefinition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudentMobileUi.body(context),
                  )
                else
                  Text(
                    word.pos ?? t.wordUnknownType,
                    style: StudentMobileUi.caption(context).copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
