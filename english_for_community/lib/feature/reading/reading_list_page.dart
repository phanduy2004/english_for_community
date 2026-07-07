import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/e4c_scroll_behavior.dart';
import '../../core/ui/skill_list_search_mixin.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/entity/reading/reading_entity.dart';
import '../../core/entity/reading/reading_progress_entity.dart';
import '../../core/get_it/get_it.dart';
import 'reading_detail_page.dart';
import 'bloc/reading_bloc.dart';
import 'bloc/reading_event.dart';
import 'bloc/reading_state.dart';

class ReadingListPage extends StatefulWidget {
  const ReadingListPage({super.key});

  static const String routeName = 'ReadingListPage';
  static const String routePath = '/reading-list';

  @override
  State<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends State<ReadingListPage> with SkillListSearchMixin {
  String _selectedDifficulty = 'easy';
  late final ReadingBloc _bloc;

  // Chưa có load-more thật → tạm nâng trần 1 lần tải để bài thứ >10 vẫn hiện & search
  // được (trước đây cứng limit:10 nên bài 11+ không bao giờ tới được).
  // TODO: chuyển sang phân trang theo pagination.hasNextPage + search phía server.
  static const int _kListLimit = 50;

  @override
  void initState() {
    super.initState();
    initSkillListSearch();
    _bloc = getIt<ReadingBloc>()
      ..add(FetchReadingListEvent(
        difficulty: _selectedDifficulty,
        page: 1,
        limit: _kListLimit,
      ));
  }

  @override
  void dispose() {
    disposeSkillListSearch();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final filterLabels = [
      t.difficultyBeginner,
      t.difficultyIntermediate,
      t.difficultyAdvanced,
    ];
    const filterIds = ['easy', 'medium', 'hard'];

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ReadingBloc, ReadingState>(
        buildWhen: (prev, next) => prev.status != next.status,
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: StudentMobileUi.skillAppBar(
              context,
              title: t.readingPracticeTitle,
              skill: SkillType.reading,
              showLoading: state.status == ReadingStatus.loading,
            ),
            body: SafeArea(
              child: e4cNoScrollbarScroll(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: StudentMobileUi.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StudentMobileUi.skillHubBanner(
                              context: context,
                              title: t.readingSkillsHeaderTitle,
                              subtitle: t.readingSkillsHeaderSubtitle,
                              badge: t.readingDailyArticlesBadge,
                              icon: Icons.menu_book_rounded,
                              skill: SkillType.reading,
                            ),
                            const SizedBox(height: StudentMobileUi.sectionGap),
                            StudentMobileUi.filterRow(
                              labels: filterLabels,
                              selectedIndex: filterIds.indexOf(_selectedDifficulty),
                              skill: SkillType.reading,
                              onSelected: (i) {
                                final next = filterIds[i];
                                if (next == _selectedDifficulty) return;
                                setState(() => _selectedDifficulty = next);
                                _bloc.add(FetchReadingListEvent(
                                  difficulty: _selectedDifficulty,
                                  page: 1,
                                  limit: _kListLimit,
                                ));
                              },
                            ),
                            const SizedBox(height: StudentMobileUi.cardGap),
                            StudentMobileUi.searchField(
                              controller: skillListSearchController,
                              hintText: t.searchTopicHint,
                              onClear: () => clearSkillListSearch(context),
                            ),
                            const SizedBox(height: StudentMobileUi.sectionGap),
                          ],
                        ),
                      ),
                    ),
                    BlocBuilder<ReadingBloc, ReadingState>(
                      builder: (context, state) {
                        if (state.status == ReadingStatus.loading && state.readings.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                              child: Center(child: StudentMobileUi.listLoading()),
                            ),
                          );
                        }
                        if (state.status == ReadingStatus.error) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: StudentMobileUi.pagePadding,
                              child: StudentMobileUi.errorBanner(
                                message: state.errorMessage ?? t.loadDataFailed,
                                onRetry: _retry,
                                retryLabel: t.commonRetry,
                              ),
                            ),
                          );
                        }

                        final readings = state.readings
                            .where((item) => skillListMatchesPrefix(
                                  item.title,
                                  skillListSearchQuery,
                                ))
                            .toList();

                        if (readings.isEmpty) {
                          return SliverFillRemaining(
                            child: StudentMobileUi.emptyState(
                              context,
                              icon: Icons.article_outlined,
                              title: t.noReadingArticlesFound,
                              body: t.searchTopicHint,
                              skill: SkillType.reading,
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            StudentMobileUi.pageHPadding,
                            0,
                            StudentMobileUi.pageHPadding,
                            StudentMobileUi.pageBottomPadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final reading = readings[index];
                                return Padding(
                                  key: ValueKey(reading.id),
                                  padding: const EdgeInsets.only(
                                    bottom: StudentMobileUi.cardGap,
                                  ),
                                  child: _ReadingCard(
                                    t: t,
                                    reading: reading,
                                    onAction: (isRetake) => _handleAction(
                                      context,
                                      reading,
                                      isRetake: isRetake,
                                    ),
                                  ),
                                );
                              },
                              childCount: readings.length,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _retry() {
    _bloc.add(FetchReadingListEvent(
      difficulty: _selectedDifficulty,
      page: 1,
      limit: _kListLimit,
      forceRefresh: true,
    ));
  }

  void _handleAction(
    BuildContext context,
    ReadingEntity reading, {
    bool isRetake = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingDetailPage(reading: reading, isRetake: isRetake),
      ),
    ).then((_) {
      if (context.mounted) {
        _bloc.add(FetchReadingListEvent(
          difficulty: _selectedDifficulty,
          page: 1,
          limit: _kListLimit,
          forceRefresh: true,
        ));
      }
    });
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.t,
    required this.reading,
    required this.onAction,
  });

  final AppLocalizations t;
  final ReadingEntity reading;
  final void Function(bool isRetake) onAction;

  String _getLevelText(ReadingDifficulty? difficulty) {
    switch (difficulty) {
      case ReadingDifficulty.easy:
        return t.difficultyBeginner;
      case ReadingDifficulty.medium:
        return t.difficultyIntermediate;
      case ReadingDifficulty.hard:
        return t.difficultyAdvanced;
      default:
        return t.unknownLevel;
    }
  }

  String? _difficultyKey(ReadingDifficulty? d) {
    switch (d) {
      case ReadingDifficulty.easy:
        return 'easy';
      case ReadingDifficulty.medium:
        return 'medium';
      case ReadingDifficulty.hard:
        return 'hard';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = reading.progress;
    final isCompleted = progress?.status == ProgressStatus.completed;
    final scoreText = (progress != null && progress.highScore > 0)
        ? t.readingScorePercent(progress.highScore.toStringAsFixed(0))
        : null;
    final levelColor = StudentMobileUi.difficultyColor(_difficultyKey(reading.difficulty));

    return StudentMobileUi.skillAccentCard(
      skill: SkillType.reading,
      tapViaChildActionsOnWeb: true,
      onTap: () => onAction(false),
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
                    Row(
                      children: [
                        _Badge(
                          label: _getLevelText(reading.difficulty),
                          color: levelColor,
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: AppSpacing.s3),
                          _Badge(
                            label: t.completedBadge,
                            color: AppColors.success,
                            filled: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      reading.title,
                      style: StudentMobileUi.cardTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      reading.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StudentMobileUi.body(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s5),
              StudentMobileUi.skillIconBox(
                Icons.article_outlined,
                skill: SkillType.reading,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          const Divider(height: 1, color: AppColors.outlineMuted),
          const SizedBox(height: AppSpacing.s4),
          StudentMobileUi.skillListCardFooter(
            info: Wrap(
              spacing: AppSpacing.s4,
              runSpacing: AppSpacing.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _IconText(
                  icon: Icons.schedule,
                  text: t.readingMinutesShort(reading.minutesToRead),
                ),
                if (reading.questions.isNotEmpty)
                  _IconText(
                    icon: Icons.quiz_outlined,
                    text: t.readingQuizCount(reading.questions.length),
                  ),
                if (scoreText != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        scoreText,
                        style: AppTypography.label(color: AppColors.success),
                      ),
                    ],
                  ),
              ],
            ),
            actions: isCompleted
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudentMobileUi.skillCardReviewButton(
                        onPressed: () => onAction(false),
                        label: t.reviewAction,
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      StudentMobileUi.skillCardRetakeButton(
                        onPressed: () => onAction(true),
                        label: t.retakeAction,
                      ),
                    ],
                  )
                : StudentMobileUi.skillCardPrimaryButton(
                    onPressed: () => onAction(false),
                    label: t.startAction,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? AppColors.successBg : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: filled ? Colors.transparent : color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label(color: color),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s2),
        Text(text, style: StudentMobileUi.caption(context)),
      ],
    );
  }
}
