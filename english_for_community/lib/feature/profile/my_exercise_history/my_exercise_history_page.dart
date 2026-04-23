import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/get_it/get_it.dart';
import '../../../core/locale/l10n_context.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/ui/animation/animated_status_container.dart';
import '../../../core/ui/interactive/scale_pressable.dart';
import '../../../core/ui/widget/app_skeleton.dart';
import '../../admin/submission_managerment/activity_detail_page.dart';
import '../../admin/submission_managerment/model/activity_model.dart';
import 'my_exercise_history_bloc.dart';
import 'my_exercise_history_event.dart';
import 'my_exercise_history_state.dart';

const Color _kBgPage = Color(0xFFF1F5F9);
const Color _kWhite = Colors.white;
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kTextMain = Color(0xFF0F172A);
const Color _kTextMuted = Color(0xFF64748B);

const Color _kColWriting = Color(0xFFF43F5E);
const Color _kColWritingBg = Color(0xFFFFF1F2);
const Color _kColReading = Color(0xFFF59E0B);
const Color _kColReadingBg = Color(0xFFFFFBEB);
const Color _kColSpeaking = Color(0xFF3B82F6);
const Color _kColSpeakingBg = Color(0xFFEFF6FF);
const Color _kColListening = Color(0xFF8B5CF6);
const Color _kColListeningBg = Color(0xFFF5F3FF);

class MyExerciseHistoryPage extends StatelessWidget {
  static const String routeName = 'MyExerciseHistoryPage';
  static const String routePath = '/my-exercise-history';

  const MyExerciseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
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
        final cs = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: cs,
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(t.exerciseHistoryTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: scheme.outlineVariant, height: 1),
        ),
      ),
      body: BlocConsumer<MyExerciseHistoryBloc, MyExerciseHistoryState>(
        listener: (context, state) {
          if (state.status == MyExerciseHistoryStatus.error &&
              state.errorMessage != null &&
              state.items.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final dateRange = state.dateRange;
          final scheme = Theme.of(context).colorScheme;

          return Column(
            children: [
              Container(
                color: scheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: _DateFilterChip(
                  range: dateRange,
                  dateRangeLabel: t.dateRangeLabel,
                  onTap: () => _pickDateRange(context, dateRange),
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              Container(
                color: scheme.surface,
                width: double.infinity,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: scheme.onSurface,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  indicatorColor: scheme.primary,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
      return const ExerciseHistoryListSkeleton();
    }
    if (state.status == MyExerciseHistoryStatus.error && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SoftErrorBanner(
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
      return _emptyState(t);
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const LoadMoreSkeletonBar();
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

  Widget _emptyState(AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kWhite,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.inbox_outlined, size: 40, color: _kTextMuted),
          ),
          const SizedBox(height: 16),
          Text(t.historyEmptyRangeTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: _kTextMain)),
          const SizedBox(height: 8),
          Text(
            t.historyEmptyRangeHint,
            style: const TextStyle(fontSize: 13, color: _kTextMuted),
          ),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final start = DateFormat('MMM dd, yy').format(range.start);
    final end = DateFormat('MMM dd, yy').format(range.end);
    return ScalePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      minScale: 0.99,
      splashColor: scheme.primary.withValues(alpha: 0.12),
      highlightColor: scheme.primary.withValues(alpha: 0.06),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.outlineMuted,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.calendar_today, size: 14, color: scheme.onSurface),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateRangeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    '$start – $end',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: scheme.onSurfaceVariant),
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

  @override
  Widget build(BuildContext context) {
    Color accentColor = _kTextMuted;
    Color accentBg = _kBgPage;
    IconData icon = Icons.article;

    switch (item.type) {
      case ActivityType.writing:
        accentColor = _kColWriting;
        accentBg = _kColWritingBg;
        icon = Icons.edit_note;
        break;
      case ActivityType.reading:
        accentColor = _kColReading;
        accentBg = _kColReadingBg;
        icon = Icons.menu_book;
        break;
      case ActivityType.listening:
        accentColor = _kColListening;
        accentBg = _kColListeningBg;
        icon = Icons.headphones;
        break;
      case ActivityType.speaking:
        accentColor = _kColSpeaking;
        accentBg = _kColSpeakingBg;
        icon = Icons.mic;
        break;
      default:
        break;
    }

    final scheme = Theme.of(context).colorScheme;
    return ScalePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      minScale: 0.985,
      splashColor: scheme.primary.withValues(alpha: 0.1),
      highlightColor: scheme.primary.withValues(alpha: 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(item.date.toLocal()),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  _statusBadge(item.status),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.outlineMuted),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.subType != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              item.subType!.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _scoreChip(item),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(ActivityModel item) {
    if ((item.status == ActivityStatus.pending || item.status == ActivityStatus.draft) && item.type == ActivityType.writing) {
      return const SizedBox.shrink();
    }

    final display = item.type == ActivityType.writing ? item.score.toString() : '${item.score.toInt()}';
    final unit = item.type == ActivityType.writing ? 'Band' : '%';
    final isGood = item.type == ActivityType.writing ? item.score >= 5.0 : item.score >= 50;
    final color = isGood ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kBgPage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Text(display, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          Text(unit, style: const TextStyle(fontSize: 10, color: _kTextMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusBadge(ActivityStatus status) {
    String text;
    Color color;
    Color bg;

    switch (status) {
      case ActivityStatus.pending:
        text = 'Pending';
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        break;
      case ActivityStatus.reviewed:
        text = 'Reviewed';
        color = const Color(0xFF16A34A);
        bg = const Color(0xFFDCFCE7);
        break;
      case ActivityStatus.draft:
        text = 'Draft';
        color = _kTextMuted;
        bg = _kBgPage;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
