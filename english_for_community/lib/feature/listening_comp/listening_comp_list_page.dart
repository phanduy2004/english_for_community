import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/feature/listening_comp/bloc_list/listening_comp_list_event.dart';
import 'package:english_for_community/feature/listening_comp/bloc_list/listening_comp_list_state.dart';

import '../../core/entity/listening_comp_entity.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bloc_list/listening_comp_list_bloc.dart';

class ListeningCompListPage extends StatefulWidget {
  const ListeningCompListPage({super.key});

  static const routeName = 'ListeningCompListPage';
  static const routePath = '/listening-comp-list';

  @override
  State<ListeningCompListPage> createState() => _ListeningCompListPageState();
}

class _ListeningCompListPageState extends State<ListeningCompListPage> {
  int _selectedFilterIndex = 0;
  static const List<String> _difficultyApiKeys = ['easy', 'medium', 'hard'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _getDifficultyForIndex(int index) => _difficultyApiKeys[index];

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

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final filterLabels = [
      t.difficultyBeginner,
      t.difficultyIntermediate,
      t.difficultyAdvanced,
    ];

    return BlocProvider<ListeningCompListBloc>(
      create: (_) => getIt<ListeningCompListBloc>()
        ..add(FetchListeningCompList(
          difficulty: _getDifficultyForIndex(_selectedFilterIndex),
        )),
      child: Builder(
        builder: (context) {
          void refreshList() {
            context.read<ListeningCompListBloc>().add(
                  FetchListeningCompList(
                    difficulty: _getDifficultyForIndex(_selectedFilterIndex),
                  ),
                );
          }

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: StudentMobileUi.skillAppBar(
              context,
              title: t.listeningCompTitle,
              skill: SkillType.listening,
            ),
            body: SafeArea(
              child: ListView(
                padding: StudentMobileUi.pagePadding,
                clipBehavior: Clip.none,
                children: [
                  StudentMobileUi.skillHubBanner(
                    context: context,
                    title: t.listeningCompTitle,
                    subtitle: t.listeningCompSubtitle,
                    icon: Icons.quiz_outlined,
                    skill: SkillType.listening,
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  StudentMobileUi.searchField(
                    controller: _searchController,
                    hintText: t.listeningCompSearchHint,
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
                      context.read<ListeningCompListBloc>().add(
                            FetchListeningCompList(
                              difficulty: _getDifficultyForIndex(i),
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  BlocBuilder<ListeningCompListBloc, ListeningCompListState>(
                    builder: (context, state) {
                      if (state.status == CompListStatus.loading) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                          child: Center(
                            child: StudentMobileUi.listLoading(),
                          ),
                        );
                      }
                      if (state.status == CompListStatus.error) {
                        return StudentMobileUi.errorBanner(
                          message: state.errorMessage ?? t.genericLoadError,
                          onRetry: refreshList,
                          retryLabel: t.commonRetry,
                        );
                      }

                      final items = state.listData
                          .where((item) => _matchesPrefix(item.title, _searchQuery))
                          .toList();
                      if (items.isEmpty && state.status == CompListStatus.success) {
                        return StudentMobileUi.emptyState(
                          context,
                          icon: Icons.quiz_outlined,
                          title: t.listeningCompEmpty,
                          body: t.listeningCompSearchHint,
                          skill: SkillType.listening,
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: StudentMobileUi.cardGap),
                        itemBuilder: (context, index) => _ListeningCompCard(
                          entity: items[index],
                          onLessonFinished: refreshList,
                          t: t,
                        ),
                      );
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

class _ListeningCompCard extends StatelessWidget {
  const _ListeningCompCard({
    required this.entity,
    required this.t,
    this.onLessonFinished,
  });

  final ListeningCompEntity entity;
  final AppLocalizations t;
  final VoidCallback? onLessonFinished;

  @override
  Widget build(BuildContext context) {
    final levelText = entity.difficulty == 'hard'
        ? t.difficultyAdvanced
        : (entity.difficulty == 'medium'
            ? t.difficultyIntermediate
            : t.difficultyBeginner);
    final levelColor = StudentMobileUi.difficultyColor(entity.difficulty);
    final isCompleted = entity.userProgress >= 1.0;
    final score = entity.highScore;

    return StudentMobileUi.skillAccentCard(
      skill: SkillType.listening,
      onTap: () => _handleRetakeOrStart(context),
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
                      entity.title,
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
                          t.listeningCompQuestionCount(entity.totalQuestions),
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
                          t.readingMinutesShort(entity.minutesToComplete),
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
                child: isCompleted
                    ? Text(
                        t.listeningCompHighScore(score),
                        style: AppTypography.label(color: AppColors.success),
                      )
                    : Text(
                        t.listeningCompNotStarted,
                        style: StudentMobileUi.caption(context).copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              if (isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StudentMobileUi.skillCardReviewButton(
                      onPressed: () => _handleRetakeOrStart(context, isRetake: false),
                      label: t.listeningCompReview,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    StudentMobileUi.skillCardRetakeButton(
                      onPressed: () => _handleRetakeOrStart(context, isRetake: true),
                      label: t.listeningCompRetake,
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: () => _handleRetakeOrStart(context, isRetake: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
                    ),
                    child: Text(
                      t.listeningCompStart,
                      style: AppTypography.label(color: AppColors.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRetakeOrStart(BuildContext context, {bool isRetake = false}) async {
    await context.pushNamed(
      'ListeningCompPage',
      pathParameters: {'id': entity.id},
      queryParameters: {'isRetake': isRetake.toString()},
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? AppColors.successBg : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: filled ? Colors.transparent : color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(label, style: AppTypography.label(color: color)),
    );
  }
}
