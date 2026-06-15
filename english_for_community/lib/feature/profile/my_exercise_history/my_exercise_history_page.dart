import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import '../../../core/get_it/get_it.dart';
import '../../../core/locale/l10n_context.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/theme/app_skill_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/interactive/scale_pressable.dart';
import '../../../core/ui/motion/app_loading_indicator.dart';
import '../../../core/ui/student_mobile_ui.dart';
import '../../../core/ui/widget/app_card.dart';
import '../../admin/submission_managerment/activity_detail_page.dart';
import '../../admin/submission_managerment/model/activity_model.dart';
import 'my_exercise_history_bloc.dart';
import 'my_exercise_history_event.dart';
import 'my_exercise_history_state.dart';

class MyExerciseHistoryPage extends StatelessWidget {
  static const String routeName = 'MyExerciseHistoryPage';
  static const String routePath = '/my-exercise-history';

  const MyExerciseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    return BlocProvider(
      create: (_) => getIt<MyExerciseHistoryBloc>()
        ..add(MyExerciseHistoryFetch(
          dateRange: DateTimeRange(start: start, end: end),
          skillFilter: null,
        )),
      child: const _MyExerciseHistoryView(),
    );
  }
}

class _MyExerciseHistoryView extends StatefulWidget {
  const _MyExerciseHistoryView();

  @override
  State<_MyExerciseHistoryView> createState() => _MyExerciseHistoryViewState();
}

class _MyExerciseHistoryViewState extends State<_MyExerciseHistoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    ActivityType? type;
    switch (_tabController.index) {
      case 1:
        type = ActivityType.reading;
        break;
      case 2:
        type = ActivityType.listening;
        break;
      case 3:
        type = ActivityType.speaking;
        break;
      case 4:
        type = ActivityType.writing;
        break;
      default:
        type = null;
    }
    final s = context.read<MyExerciseHistoryBloc>().state;
    context.read<MyExerciseHistoryBloc>().add(MyExerciseHistoryFetch(
          dateRange: s.dateRange,
          skillFilter: type,
        ));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 120) return;
    context.read<MyExerciseHistoryBloc>().add(MyExerciseHistoryLoadMore());
  }

  Future<void> _pickDateRange(BuildContext context, DateTimeRange currentRange) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      final s = context.read<MyExerciseHistoryBloc>().state;
      context.read<MyExerciseHistoryBloc>().add(MyExerciseHistoryFetch(
            dateRange: picked,
            skillFilter: s.skillFilter,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.appBar(context, title: t.exerciseHistoryTitle),
      body: BlocConsumer<MyExerciseHistoryBloc, MyExerciseHistoryState>(
        listener: (context, state) {
          if (state.status == MyExerciseHistoryStatus.error &&
              state.errorMessage != null &&
              state.items.isNotEmpty) {
            AppCornerToast.show(context, state.errorMessage!, error: true);
          }
        },
        builder: (context, state) {
          final dateRange = state.dateRange;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StudentMobileUi.pageHPadding,
                  AppSpacing.s5,
                  StudentMobileUi.pageHPadding,
                  AppSpacing.s4,
                ),
                child: _DateFilterChip(
                  range: dateRange,
                  dateRangeLabel: t.dateRangeLabel,
                  onTap: () => _pickDateRange(context, dateRange),
                ),
              ),
              const Divider(height: 1, color: AppColors.outlineMuted),
              Container(
                color: AppColors.surface,
                width: double.infinity,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabAlignment: TabAlignment.start,
                  labelStyle: AppTypography.label(),
                  padding: const EdgeInsets.symmetric(horizontal: StudentMobileUi.pageHPadding),
                  tabs: [
                    Tab(text: t.skillTabAll),
                    Tab(text: t.skillTabReading),
                    Tab(text: t.skillTabListening),
                    Tab(text: t.skillTabSpeaking),
                    Tab(text: t.skillTabWriting),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>(_historyBodyPhase(state)),
                    child: _buildHistoryBody(context, state, t),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _historyBodyPhase(MyExerciseHistoryState state) {
    final loadingEmpty = state.items.isEmpty &&
        (state.status == MyExerciseHistoryStatus.loading ||
            state.status == MyExerciseHistoryStatus.initial);
    if (loadingEmpty) return 'loading';
    if (state.status == MyExerciseHistoryStatus.error && state.items.isEmpty) return 'error';
    if (state.items.isEmpty) return 'empty';
    return 'list';
  }

  Widget _buildHistoryBody(BuildContext context, MyExerciseHistoryState state, AppLocalizations t) {
    final loadingEmpty = state.items.isEmpty &&
        (state.status == MyExerciseHistoryStatus.loading ||
            state.status == MyExerciseHistoryStatus.initial);
    if (loadingEmpty) {
      return StudentMobileUi.pageLoading();
    }
    if (state.status == MyExerciseHistoryStatus.error && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s7),
          child: StudentMobileUi.errorBanner(
            message: state.errorMessage ?? t.couldNotLoadExerciseHistory,
            onRetry: () => context.read<MyExerciseHistoryBloc>().add(MyExerciseHistoryFetch(
                  dateRange: state.dateRange,
                  skillFilter: state.skillFilter,
                )),
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.inbox_outlined,
        title: t.historyEmptyRangeTitle,
        body: t.historyEmptyRangeHint,
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: StudentMobileUi.pagePadding,
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: StudentMobileUi.cardGap),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s5),
            child: Center(child: AppLoadingIndicator.center()),
          );
        }
        final item = state.items[index];
        return _UserHistoryCard(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityDetailPage(
                  id: item.id,
                  type: item.type,
                  summaryTitle: item.title,
                  summaryDate: item.date,
                  subType: item.subType,
                  useUserActivityApi: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final DateTimeRange range;
  final String dateRangeLabel;
  final VoidCallback onTap;

  const _DateFilterChip({required this.range, required this.dateRangeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('MMM dd, yy').format(range.start);
    final end = DateFormat('MMM dd, yy').format(range.end);
    return ScalePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      minScale: 0.99,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primaryTint,
      child: AppCard(
        variant: AppCardVariant.outline,
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
        child: Row(
          children: [
            StudentMobileUi.skillIconBox(Icons.calendar_today_outlined, size: 32),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateRangeLabel, style: StudentMobileUi.caption(context)),
                  Text(
                    '$start – $end',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(color: AppColors.textPrimary, large: true),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _UserHistoryCard extends StatelessWidget {
  final ActivityModel item;
  final VoidCallback onTap;

  const _UserHistoryCard({required this.item, required this.onTap});

  IconData _skillIcon(ActivityType type) {
    switch (type) {
      case ActivityType.writing:
        return Icons.edit_note_outlined;
      case ActivityType.reading:
        return Icons.menu_book_outlined;
      case ActivityType.listening:
        return Icons.headphones_outlined;
      case ActivityType.speaking:
        return Icons.mic_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  SkillType? _skillType(ActivityType type) {
    switch (type) {
      case ActivityType.writing:
        return SkillType.writing;
      case ActivityType.reading:
        return SkillType.reading;
      case ActivityType.listening:
        return SkillType.listening;
      case ActivityType.speaking:
        return SkillType.speaking;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = _skillType(item.type);
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(item.date.toLocal()),
              style: StudentMobileUi.caption(context),
            ),
            const Spacer(),
            _statusBadge(item.status),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
          child: Divider(height: 1, color: AppColors.outlineMuted),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentMobileUi.skillIconBox(
              _skillIcon(item.type),
              size: 40,
              skill: skill,
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.subType != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                      child: Text(
                        item.subType!.toUpperCase(),
                        style: AppTypography.label(color: AppColors.textSecondary),
                      ),
                    ),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StudentMobileUi.cardTitle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            _scoreChip(context, item),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: skill != null
                  ? AppSkillColors.of(skill).color
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ],
    );

    if (skill != null) {
      return StudentMobileUi.skillAccentCard(
        skill: skill,
        onTap: onTap,
        child: card,
      );
    }

    return AppCard(
      variant: AppCardVariant.outline,
      radius: 12,
      padding: const EdgeInsets.all(AppSpacing.s5),
      onTap: onTap,
      child: card,
    );
  }

  Widget _scoreChip(BuildContext context, ActivityModel item) {
    if ((item.status == ActivityStatus.pending || item.status == ActivityStatus.draft) &&
        item.type == ActivityType.writing) {
      return const SizedBox.shrink();
    }

    final display = item.type == ActivityType.writing ? item.score.toString() : '${item.score.toInt()}';
    final unit = item.type == ActivityType.writing ? 'Band' : '%';
    final isGood = item.type == ActivityType.writing ? item.score >= 5.0 : item.score >= 50;
    final color = isGood ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Text(display, style: StudentMobileUi.kpi(context).copyWith(color: color)),
          Text(unit, style: AppTypography.label(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _statusBadge(ActivityStatus status) {
    String text;
    Color fg;
    Color bg;

    switch (status) {
      case ActivityStatus.pending:
        text = 'Pending';
        fg = AppColors.warning;
        bg = AppColors.warningBg;
        break;
      case ActivityStatus.reviewed:
        text = 'Reviewed';
        fg = AppColors.success;
        bg = AppColors.successBg;
        break;
      case ActivityStatus.draft:
        text = 'Draft';
        fg = AppColors.textSecondary;
        bg = AppColors.surfaceSubtle;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(text, style: AppTypography.label(color: fg)),
    );
  }
}
