import 'package:english_for_community/core/get_it/get_it.dart';

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

import '../../core/ui/e4c_scroll_behavior.dart';

import '../../core/ui/skill_list_search_mixin.dart';

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



class _ListeningCompListPageState extends State<ListeningCompListPage>

    with SkillListSearchMixin {

  int _selectedFilterIndex = 0;

  static const List<String> _difficultyApiKeys = ['easy', 'medium', 'hard'];

  late final ListeningCompListBloc _bloc;



  String _getDifficultyForIndex(int index) => _difficultyApiKeys[index];



  @override

  void initState() {

    super.initState();

    initSkillListSearch();

    _bloc = getIt<ListeningCompListBloc>()

      ..add(FetchListeningCompList(

        difficulty: _getDifficultyForIndex(_selectedFilterIndex),

      ));

  }



  @override

  void dispose() {

    disposeSkillListSearch();

    _bloc.close();

    super.dispose();

  }



  void _refreshList() {

    _bloc.add(FetchListeningCompList(

      difficulty: _getDifficultyForIndex(_selectedFilterIndex),

      forceRefresh: true,

    ));

  }



  @override

  Widget build(BuildContext context) {

    final t = context.l10n;

    final filterLabels = [

      t.difficultyBeginner,

      t.difficultyIntermediate,

      t.difficultyAdvanced,

    ];



    return BlocProvider.value(

      value: _bloc,

      child: BlocBuilder<ListeningCompListBloc, ListeningCompListState>(

        buildWhen: (prev, next) => prev.status != next.status,

        builder: (context, state) {

          return Scaffold(

        backgroundColor: AppColors.surface,

        appBar: StudentMobileUi.skillAppBar(

          context,

          title: t.listeningCompTitle,

          skill: SkillType.listening,

          showLoading: state.status == CompListStatus.loading,

        ),

        body: SafeArea(

          child: e4cNoScrollbarScroll(

            child: CustomScrollView(

              physics: const BouncingScrollPhysics(),

              clipBehavior: Clip.none,

              slivers: [

                SliverToBoxAdapter(

                  child: Padding(

                    padding: StudentMobileUi.pagePadding,

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.stretch,

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

                          controller: skillListSearchController,

                          hintText: t.listeningCompSearchHint,

                          onClear: () => clearSkillListSearch(context),

                        ),

                        const SizedBox(height: StudentMobileUi.cardGap),

                        StudentMobileUi.filterRow(

                          labels: filterLabels,

                          selectedIndex: _selectedFilterIndex,

                          skill: SkillType.listening,

                          onSelected: (i) {

                            if (i == _selectedFilterIndex) return;

                            setState(() => _selectedFilterIndex = i);

                            _bloc.add(FetchListeningCompList(

                              difficulty: _getDifficultyForIndex(i),

                            ));

                          },

                        ),

                        const SizedBox(height: StudentMobileUi.sectionGap),

                      ],

                    ),

                  ),

                ),

                BlocBuilder<ListeningCompListBloc, ListeningCompListState>(

                  builder: (context, state) {

                    if (state.status == CompListStatus.loading && state.listData.isEmpty) {

                      return SliverToBoxAdapter(

                        child: Padding(

                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),

                          child: Center(child: StudentMobileUi.listLoading()),

                        ),

                      );

                    }

                    if (state.status == CompListStatus.error) {

                      return SliverToBoxAdapter(

                        child: Padding(

                          padding: StudentMobileUi.pagePadding,

                          child: StudentMobileUi.errorBanner(

                            message: state.errorMessage ?? t.genericLoadError,

                            onRetry: _refreshList,

                            retryLabel: t.commonRetry,

                          ),

                        ),

                      );

                    }



                    final items = state.listData

                        .where((item) => skillListMatchesPrefix(

                              item.title,

                              skillListSearchQuery,

                            ))

                        .toList();

                    if (items.isEmpty && state.status == CompListStatus.success) {

                      return SliverFillRemaining(

                        child: StudentMobileUi.emptyState(

                          context,

                          icon: Icons.quiz_outlined,

                          title: t.listeningCompEmpty,

                          body: t.listeningCompSearchHint,

                          skill: SkillType.listening,

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

                          (context, index) => Padding(

                            key: ValueKey(items[index].id),

                            padding: const EdgeInsets.only(

                              bottom: StudentMobileUi.cardGap,

                            ),

                            child: _ListeningCompCard(

                              entity: items[index],

                              onLessonFinished: _refreshList,

                              t: t,

                            ),

                          ),

                          childCount: items.length,

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

      tapViaChildActionsOnWeb: true,

      elevated: true,

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

          StudentMobileUi.skillListCardFooter(

            info: isCompleted

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

            actions: isCompleted

                ? Row(

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

                : StudentMobileUi.skillCardPrimaryButton(

                    onPressed: () => _handleRetakeOrStart(context, isRetake: false),

                    label: t.listeningCompStart,

                  ),

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


