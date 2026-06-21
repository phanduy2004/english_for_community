import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';

import '../listening_skill/bloc/cue_bloc.dart';
import '../listening_skill/bloc/cue_event.dart';
import '../listening_skill/listening_skills_page.dart';
import 'bloc/listening_bloc.dart';
import 'bloc/listening_event.dart';
import 'bloc/listening_state.dart';

class ListeningListPage extends StatefulWidget {
  const ListeningListPage({super.key});

  static const routeName = 'ListeningListPage';
  static const routePath = '/listening-list';

  @override
  State<ListeningListPage> createState() => _ListeningListPageState();
}

class _ListeningListPageState extends State<ListeningListPage> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDifficultyForIndex(int index) {
    switch (index) {
      case 0:
        return 'easy';
      case 1:
        return 'medium';
      case 2:
        return 'hard';
      default:
        return 'easy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final filterLabels = [
      t.difficultyBeginner,
      t.difficultyIntermediate,
      t.difficultyAdvanced,
    ];

    return BlocProvider<ListeningBloc>(
      create: (_) => getIt<ListeningBloc>()
        ..add(GetListListeningEvent(
          difficulty: _getDifficultyForIndex(_selectedFilterIndex),
        )),
      child: Builder(
        builder: (context) {
          void refreshList() {
            context.read<ListeningBloc>().add(
                  GetListListeningEvent(
                    difficulty: _getDifficultyForIndex(_selectedFilterIndex),
                  ),
                );
          }

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: StudentMobileUi.skillAppBar(
              context,
              title: t.listeningPracticeTitle,
              skill: SkillType.listening,
            ),
            body: SafeArea(
              child: ListView(
                padding: StudentMobileUi.pagePadding,
                clipBehavior: Clip.none,
                children: [
                  StudentMobileUi.skillHubBanner(
                    context: context,
                    title: t.listeningHeaderTitle,
                    subtitle: t.listeningHeaderSubtitle,
                    badge: t.listeningPremiumBadge,
                    icon: Icons.headphones_rounded,
                    skill: SkillType.listening,
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  StudentMobileUi.searchField(
                    controller: _searchController,
                    hintText: t.listeningSearchHint,
                    showClear: _searchQuery.trim().isNotEmpty,
                    onClear: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: StudentMobileUi.cardGap),
                  StudentMobileUi.filterRow(
                    labels: filterLabels,
                    selectedIndex: _selectedFilterIndex,
                    skill: SkillType.listening,
                    onSelected: (i) {
                      setState(() => _selectedFilterIndex = i);
                      context.read<ListeningBloc>().add(
                            GetListListeningEvent(
                              difficulty: _getDifficultyForIndex(i),
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  BlocBuilder<ListeningBloc, ListeningState>(
                    builder: (context, state) {
                      switch (state.status) {
                        case ListeningStatus.loading:
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                            child: Center(
                              child: StudentMobileUi.listLoading(),
                            ),
                          );
                        case ListeningStatus.error:
                          return StudentMobileUi.errorBanner(
                            message: state.errorMessage ?? t.loadDataFailed,
                            onRetry: refreshList,
                            retryLabel: t.commonRetry,
                          );
                        case ListeningStatus.success:
                          final allItems =
                              state.listListeningEntity ?? const <ListeningEntity>[];
                          final items = allItems
                              .where((item) => _matchesPrefix(item.title, _searchQuery))
                              .toList();
                          if (items.isEmpty) {
                            return StudentMobileUi.emptyState(
                              context,
                              icon: Icons.headphones_outlined,
                              title: t.noListeningLessonsFound,
                              body: t.listeningSearchHint,
                              skill: SkillType.listening,
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: StudentMobileUi.cardGap),
                            itemBuilder: (context, index) => _ListeningCard(
                              t: t,
                              entity: items[index],
                              onLessonFinished: refreshList,
                            ),
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _matchesPrefix(String source, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return source.trimLeft().toLowerCase().startsWith(normalizedQuery);
  }
}

class _ListeningCard extends StatelessWidget {
  const _ListeningCard({
    required this.t,
    required this.entity,
    this.onLessonFinished,
  });

  final AppLocalizations t;
  final ListeningEntity entity;
  final VoidCallback? onLessonFinished;

  String _difficultyLabel(ListeningDifficulty? d) {
    switch (d) {
      case ListeningDifficulty.easy:
        return t.difficultyBeginner;
      case ListeningDifficulty.medium:
        return t.difficultyIntermediate;
      case ListeningDifficulty.hard:
        return t.difficultyAdvanced;
      default:
        return t.unknownLevel;
    }
  }

  String? _difficultyKey(ListeningDifficulty? d) {
    switch (d) {
      case ListeningDifficulty.easy:
        return 'easy';
      case ListeningDifficulty.medium:
        return 'medium';
      case ListeningDifficulty.hard:
        return 'hard';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = entity.title;
    final totalCues = entity.totalCues ?? 0;
    final levelText = _difficultyLabel(entity.difficulty);
    final levelColor = StudentMobileUi.difficultyColor(_difficultyKey(entity.difficulty));
    final progress = entity.userProgress.clamp(0.0, 1.0);
    final isCompleted = progress >= 0.99;

    return StudentMobileUi.skillAccentCard(
      skill: SkillType.listening,
      onTap: () => _handlePress(context, isRetake: false),
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
                        _Badge(label: levelText, color: levelColor),
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
                      title,
                      style: StudentMobileUi.cardTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Row(
                      children: [
                        const Icon(
                          Icons.format_list_bulleted,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          t.questionsCount(totalCues),
                          style: StudentMobileUi.body(context),
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          t.listeningDictation,
                          style: StudentMobileUi.body(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              StudentMobileUi.skillIconBox(
                isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                skill: SkillType.listening,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          const Divider(height: 1, color: AppColors.outlineMuted),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentMobileUi.skillProgressBar(
                      value: progress,
                      skill: SkillType.listening,
                      height: 4,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      t.progressPercentLabel((progress * 100).toInt()),
                      style: StudentMobileUi.caption(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s5),
              if (isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StudentMobileUi.skillCardReviewButton(
                      onPressed: () => _handlePress(context, isRetake: false),
                      label: t.reviewAction,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    StudentMobileUi.skillCardRetakeButton(
                      onPressed: () => _handlePress(context, isRetake: true),
                      label: t.retakeAction,
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: () => _handlePress(context, isRetake: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
                    ),
                    child: Text(t.startAction, style: AppTypography.label(color: AppColors.onPrimary)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePress(BuildContext context, {bool isRetake = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<CueBloc>(
          create: (_) => getIt<CueBloc>()
            ..add(LoadCuesAndAttempts(
              listeningId: entity.id,
              isRetake: isRetake,
            )),
          child: ListeningSkillsPage(
            listeningId: entity.id,
            title: entity.title,
            levelText: _difficultyLabel(entity.difficulty),
            audioUrl: entity.audioUrl,
          ),
        ),
      ),
    );
    if (context.mounted) {
      onLessonFinished?.call();
    }
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
    if (label.isEmpty && filled) return const SizedBox.shrink();
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
