import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/skill_list_search_mixin.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_event.dart';
import 'package:english_for_community/feature/writing/bloc/writing_state.dart';
import 'package:english_for_community/feature/writing/writing_task_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/writing_card.dart';
import 'widgets/history_modal.dart';

class WritingTopicsPage extends StatefulWidget {
  const WritingTopicsPage({super.key});

  static const routeName = 'WritingTopicsPage';
  static const routePath = '/writing-topics';

  @override
  State<WritingTopicsPage> createState() => _WritingTopicsPageState();
}

class _WritingTopicsPageState extends State<WritingTopicsPage> with SkillListSearchMixin {
  late final WritingBloc _writingBloc;

  int _selectedFilterIndex = 0;
  static const _levelFilterKeys = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    initSkillListSearch();
    _writingBloc = getIt<WritingBloc>();
    _writingBloc.add(GetWritingTopicsEvent());
  }

  @override
  void dispose() {
    disposeSkillListSearch();
    _writingBloc.close();
    super.dispose();
  }

  ({IconData icon, Color color, String desc}) _getTaskTypeConfig(
    String type,
    AppLocalizations t,
  ) {
    final s = type.toLowerCase();
    if (s.contains('opinion') || s.contains('agree')) {
      return (
        icon: Icons.lightbulb_outline,
        color: AppColors.accent,
        desc: t.writingTaskDescOpinion,
      );
    } else if (s.contains('discuss')) {
      return (
        icon: Icons.people_outline,
        color: AppColors.info,
        desc: t.writingTaskDescDiscuss,
      );
    } else if (s.contains('problem') || s.contains('solution') || s.contains('cause')) {
      return (
        icon: Icons.build_circle_outlined,
        color: AppColors.danger,
        desc: t.writingTaskDescProblemSolution,
      );
    } else if (s.contains('advantage')) {
      return (
        icon: Icons.balance,
        color: AppColors.success,
        desc: t.writingTaskDescAdvantages,
      );
    }
    return (
      icon: Icons.edit_note,
      color: AppColors.info,
      desc: t.writingTaskDescGeneral,
    );
  }

  void _showTaskSelectionModal(BuildContext context, WritingTopicEntity topic) {
    final t = context.l10n;
    final taskTypes = topic.aiConfig?.taskTypes ??
        [
          'Opinion',
          'Discussion',
          'Problem-Solution',
          'Advantages-Disadvantages',
        ];

    StudentBottomSheet.show(
      context,
      StudentBottomSheet(
        title: t.writingSelectTaskType,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            0,
            AppSpacing.s5,
            AppSpacing.s7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.writingForTopic(topic.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StudentMobileUi.body(context),
              ),
              const SizedBox(height: StudentMobileUi.sectionGap),
              ...taskTypes.map((type) {
                final config = _getTaskTypeConfig(type, t);
                return Padding(
                  padding: const EdgeInsets.only(bottom: StudentMobileUi.cardGap),
                  child: StudentMobileUi.skillAccentCard(
                    skill: SkillType.writing,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => WritingTaskPage(
                                topic: topic,
                                selectedTaskType: type,
                              ),
                            ),
                          )
                          .then((_) {
                        if (mounted) _writingBloc.add(GetWritingTopicsEvent());
                      });
                    },
                    child: Row(
                      children: [
                        StudentMobileUi.skillIconBox(
                          config.icon,
                          size: 44,
                          skill: SkillType.writing,
                        ),
                        const SizedBox(width: AppSpacing.s5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type, style: StudentMobileUi.cardTitle(context)),
                              const SizedBox(height: AppSpacing.s1),
                              Text(config.desc, style: StudentMobileUi.body(context)),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryModal(BuildContext context, WritingTopicEntity topic) {
    _writingBloc.add(GetTopicHistoryEvent(topic.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _writingBloc,
        child: HistoryModal(
          topicName: topic.name,
          primaryColor: StudentMobileUi.difficultyColor(topic.aiConfig?.level),
        ),
      ),
    );
  }

  void _onCardTap(WritingTopicEntity item) {
    _showTaskSelectionModal(context, item);
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
      value: _writingBloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.skillAppBar(
          context,
          title: t.homeLessonWritingTitle,
          skill: SkillType.writing,
        ),
        body: e4cNoScrollbarScroll(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: StudentMobileUi.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StudentMobileUi.skillHubBanner(
                        context: context,
                        title: t.writingHeaderEssayTitle,
                        subtitle: t.writingHeaderEssaySubtitle,
                        badge: t.writingAiFeedbackBadge,
                        icon: Icons.edit_note_rounded,
                        skill: SkillType.writing,
                      ),
                      const SizedBox(height: StudentMobileUi.sectionGap),
                      StudentMobileUi.searchField(
                        controller: skillListSearchController,
                        hintText: t.writingSearchTopicsHint,
                        onClear: () => clearSkillListSearch(context),
                      ),
                      const SizedBox(height: StudentMobileUi.cardGap),
                      StudentMobileUi.filterRow(
                        labels: filterLabels,
                        selectedIndex: _selectedFilterIndex,
                        skill: SkillType.writing,
                        onSelected: (i) {
                          if (i == _selectedFilterIndex) return;
                          setState(() => _selectedFilterIndex = i);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<WritingBloc, WritingState>(
                builder: (context, state) {
                  if (state.status == WritingStatus.loading) {
                    return SliverFillRemaining(
                      child: StudentMobileUi.listLoading(),
                    );
                  }
                  if (state.status == WritingStatus.error) {
                    return SliverFillRemaining(
                      child: Padding(
                        padding: StudentMobileUi.pagePadding,
                        child: StudentMobileUi.errorBanner(
                          message: state.errorMessage ?? t.commonError,
                          onRetry: () => _writingBloc.add(GetWritingTopicsEvent()),
                          retryLabel: t.commonRetry,
                        ),
                      ),
                    );
                  }

                  var topics = state.topics;

                  final query = skillListSearchQuery.trim();
                  if (query.isNotEmpty) {
                    topics = topics
                        .where(
                          (x) => skillListMatchesPrefix(x.name, query),
                        )
                        .toList();
                  }

                  final levelKey = _levelFilterKeys[_selectedFilterIndex];
                  topics = topics
                      .where((x) => (x.aiConfig?.level ?? '').toLowerCase() == levelKey)
                      .toList();

                  if (topics.isEmpty) {
                    return SliverFillRemaining(
                      child: StudentMobileUi.emptyState(
                        context,
                        icon: Icons.edit_off_outlined,
                        title: t.writingNoTopicsFound,
                        body: t.writingSearchTopicsHint,
                        skill: SkillType.writing,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      StudentMobileUi.pageHPadding,
                      StudentMobileUi.sectionGap,
                      StudentMobileUi.pageHPadding,
                      StudentMobileUi.pageBottomPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final topicItem = topics[index];
                          return Padding(
                            key: ValueKey(topicItem.id),
                            padding: const EdgeInsets.only(bottom: StudentMobileUi.cardGap),
                            child: WritingCard(
                              title: topicItem.name,
                              leadingIcon: Icons.history_edu,
                              onTap: () => _onCardTap(topicItem),
                              onHistoryTap: () => _showHistoryModal(context, topicItem),
                              level: topicItem.aiConfig?.level,
                              submissions: topicItem.stats?.submissionsCount,
                              avgScore: topicItem.stats?.avgScore,
                            ),
                          );
                        },
                        childCount: topics.length,
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
  }
}
