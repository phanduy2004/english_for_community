import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_event.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_filter.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_navigation.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exams_list_page.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TeacherCalendarPage extends StatelessWidget {
  const TeacherCalendarPage({super.key});

  static const String routePath = '/teacher/calendar';
  static const String routeName = 'TeacherCalendarPage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherCalendarBloc>()..add(const TeacherCalendarLoadRequested()),
      child: const _TeacherCalendarView(),
    );
  }
}

abstract final class _CalendarKindStyle {
  static Color color(String? kind) {
    switch (kind) {
      case 'opens':
        return AppColors.success;
      case 'live':
        return AppColors.info;
      case 'due':
        return AppColors.warning;
      case 'closes':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  static Color bg(String? kind) {
    switch (kind) {
      case 'opens':
        return AppColors.successBg;
      case 'live':
        return AppColors.infoBg;
      case 'due':
        return AppColors.warningBg;
      case 'closes':
        return AppColors.dangerBg;
      default:
        return AppColors.surfaceSubtle;
    }
  }

  static IconData icon(String? kind) {
    switch (kind) {
      case 'opens':
        return Icons.lock_open_outlined;
      case 'live':
        return Icons.sensors_outlined;
      case 'due':
        return Icons.schedule_outlined;
      case 'closes':
        return Icons.lock_outline;
      default:
        return Icons.event_outlined;
    }
  }

  static String label(AppLocalizations l10n, String? kind) {
    switch (kind) {
      case 'due':
        return l10n.teacherCalendarKindDue;
      case 'opens':
        return l10n.teacherCalendarKindOpens;
      case 'closes':
        return l10n.teacherCalendarKindCloses;
      case 'live':
        return l10n.teacherCalendarKindLive;
      default:
        return kind ?? '';
    }
  }
}

class _CalendarKpiCounts {
  const _CalendarKpiCounts({
    required this.dueWeek,
    required this.opensSoon,
    required this.liveNow,
    required this.total,
  });

  final int dueWeek;
  final int opensSoon;
  final int liveNow;
  final int total;
}

_CalendarKpiCounts _computeKpis(List<Map<String, dynamic>> events) {
  final now = DateTime.now();
  final today = teacherCalendarDateOnly(now);
  final weekEnd = today.add(const Duration(days: 7));
  var dueWeek = 0;
  var opensSoon = 0;
  var liveNow = 0;

  for (final e in events) {
    final at = teacherCalendarEventAt(e);
    if (at == null) continue;
    final day = teacherCalendarDateOnly(at);
    final kind = e['kind'] as String?;
    if (kind == 'due' && !day.isBefore(today) && !day.isAfter(weekEnd)) dueWeek++;
    if (kind == 'opens' && !day.isBefore(today) && !day.isAfter(weekEnd)) opensSoon++;
    if (kind == 'live') liveNow++;
  }

  return _CalendarKpiCounts(
    dueWeek: dueWeek,
    opensSoon: opensSoon,
    liveNow: liveNow,
    total: events.length,
  );
}

enum _ListSection { today, upcoming, past }

Map<_ListSection, List<TeacherCalendarAssignmentGroup>> _groupListAssignmentGroups(
  List<Map<String, dynamic>> events,
) {
  final today = teacherCalendarDateOnly(DateTime.now());
  final grouped = <_ListSection, List<TeacherCalendarAssignmentGroup>>{
    _ListSection.today: [],
    _ListSection.upcoming: [],
    _ListSection.past: [],
  };

  for (final g in teacherCalendarGroupEvents(events)) {
    final primary = teacherCalendarPrimaryMilestone(g.milestones) ?? g.anchor;
    final at = teacherCalendarEventAt(primary);
    if (at == null) continue;
    final day = teacherCalendarDateOnly(at);
    if (day == today) {
      grouped[_ListSection.today]!.add(g);
    } else if (day.isAfter(today)) {
      grouped[_ListSection.upcoming]!.add(g);
    } else {
      grouped[_ListSection.past]!.add(g);
    }
  }
  return grouped;
}

class _TeacherCalendarView extends StatelessWidget {
  const _TeacherCalendarView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeacherCalendarBloc, TeacherCalendarState>(
      builder: (context, state) {
        final loading = state.status == TeacherCalendarStatus.loading;
        final error = state.status == TeacherCalendarStatus.error ? state.errorMessage : null;
        final useListScroll = !loading && error == null && state.viewMode == TeacherCalendarViewMode.list;

        return TeacherPageScaffold(
          scrollable: !useListScroll,
          title: l10n.teacherNavCalendar,
          subtitle: l10n.teacherCalendarPageSubtitle,
          breadcrumbs: [
            TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
            TeacherBreadcrumb(label: l10n.teacherNavCalendar),
          ],
          maxWidth: TeacherWebUi.contentMaxTable,
          actions: [
            TextButton(
              onPressed: () => context.read<TeacherCalendarBloc>().add(const TeacherCalendarGoToToday()),
              child: Text(l10n.teacherCalendarToday),
            ),
            const SizedBox(width: AppSpacing.s2),
            _ViewModeSegmented(
              viewMode: state.viewMode,
              onChanged: (v) => context.read<TeacherCalendarBloc>().add(TeacherCalendarViewModeChanged(v)),
            ),
            const SizedBox(width: AppSpacing.s2),
            IconButton(
              onPressed: () => context.read<TeacherCalendarBloc>().add(const TeacherCalendarLoadRequested()),
              icon: const Icon(Icons.refresh_outlined, size: 20),
              style: TeacherWebUi.compactHeaderIconStyle(),
            ),
          ],
          body: loading
              ? TeacherSkeleton.page(TeacherSkeleton.calendar())
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error, style: TeacherWebUi.webBody(context)),
                          const SizedBox(height: AppSpacing.s5),
                          TeacherRetryButton(
                            onPressed: () =>
                                context.read<TeacherCalendarBloc>().add(const TeacherCalendarLoadRequested()),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CalendarKpiRow(counts: _computeKpis(state.visibleEvents)),
                        const SizedBox(height: AppSpacing.s5),
                        _CalendarLegendBar(l10n: l10n),
                        const SizedBox(height: AppSpacing.s4),
                        _CalendarToolbar(state: state),
                        const SizedBox(height: AppSpacing.s5),
                        switch (state.viewMode) {
                          TeacherCalendarViewMode.month => _MonthScheduleBody(state: state),
                          TeacherCalendarViewMode.week => _WeekScheduleBody(state: state),
                          TeacherCalendarViewMode.list => Expanded(child: _ListScheduleBody(state: state)),
                        },
                      ],
                    ),
        );
      },
    );
  }
}

class _ViewModeSegmented extends StatelessWidget {
  const _ViewModeSegmented({required this.viewMode, required this.onChanged});

  final TeacherCalendarViewMode viewMode;
  final ValueChanged<TeacherCalendarViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<TeacherCalendarViewMode>(
      segments: [
        ButtonSegment(
          value: TeacherCalendarViewMode.month,
          label: Text(l10n.teacherCalendarViewMonth),
          icon: const Icon(Icons.calendar_month_outlined, size: 16),
        ),
        ButtonSegment(
          value: TeacherCalendarViewMode.week,
          label: Text(l10n.teacherCalendarViewWeek),
          icon: const Icon(Icons.view_week_outlined, size: 16),
        ),
        ButtonSegment(
          value: TeacherCalendarViewMode.list,
          label: Text(l10n.teacherCalendarViewList),
          icon: const Icon(Icons.view_list_outlined, size: 16),
        ),
      ],
      selected: {viewMode},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: TeacherWebUi.segmentedControlStyle(context),
    );
  }
}

class _CalendarKpiRow extends StatelessWidget {
  const _CalendarKpiRow({required this.counts});

  final _CalendarKpiCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<TeacherCalendarBloc>();

    return TeacherKpiGrid(
      children: [
        TeacherKpiCard(
          icon: Icons.schedule_outlined,
          value: '${counts.dueWeek}',
          label: l10n.teacherCalendarKpiDueWeek,
          accent: AppColors.warning,
          onTap: () => bloc.add(const TeacherCalendarKpiTapped(TeacherCalendarKindFilter.due)),
        ),
        TeacherKpiCard(
          icon: Icons.lock_open_outlined,
          value: '${counts.opensSoon}',
          label: l10n.teacherCalendarKpiOpens,
          accent: AppColors.success,
          onTap: () => bloc.add(const TeacherCalendarKpiTapped(TeacherCalendarKindFilter.opens)),
        ),
        TeacherKpiCard(
          icon: Icons.sensors_outlined,
          value: '${counts.liveNow}',
          label: l10n.teacherCalendarKpiLive,
          accent: AppColors.info,
          onTap: () => bloc.add(const TeacherCalendarKpiTapped(TeacherCalendarKindFilter.live)),
        ),
        TeacherKpiCard(
          icon: Icons.event_outlined,
          value: '${counts.total}',
          label: l10n.teacherCalendarKpiTotal,
          accent: AppColors.primary,
          onTap: () => bloc.add(const TeacherCalendarKpiTapped(TeacherCalendarKindFilter.all)),
        ),
      ],
    );
  }
}

class _CalendarLegendBar extends StatelessWidget {
  const _CalendarLegendBar({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TeacherWebUi.panelDecoration(bg: AppColors.surfaceSubtle),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      child: Wrap(
        spacing: AppSpacing.s4,
        runSpacing: AppSpacing.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.teacherCalendarLegendTitle, style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600)),
          _LegendChip(label: l10n.teacherCalendarKindOpens, color: AppColors.success),
          _LegendChip(label: l10n.teacherCalendarKindDue, color: AppColors.warning),
          _LegendChip(label: l10n.teacherCalendarKindCloses, color: AppColors.danger),
          _LegendChip(label: l10n.teacherCalendarKindLive, color: AppColors.info),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TeacherWebUi.webCaption(context)),
      ],
    );
  }
}

class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({required this.state});

  final TeacherCalendarState state;

  Widget _kindChip(BuildContext context, String label, TeacherCalendarKindFilter filter) {
    final selected = state.kindFilter == filter;
    return FilterChip(
      label: Text(label, style: TeacherWebUi.webCaption(context)),
      selected: selected,
      onSelected: (_) => context.read<TeacherCalendarBloc>().add(TeacherCalendarKindFilterChanged(filter)),
      selectedColor: AppColors.primaryTint,
      checkmarkColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.outline),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<TeacherCalendarBloc>();
    final classrooms = state.classroomOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarSearchField(
          query: state.searchQuery,
          hintText: l10n.teacherCalendarSearchHint,
          onChanged: (q) => bloc.add(TeacherCalendarSearchChanged(q)),
        ),
        const SizedBox(height: AppSpacing.s3),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (classrooms.isNotEmpty) ...[
              Text(l10n.teacherCalendarFilterClassroomLabel, style: TeacherWebUi.webCaption(context)),
              _ClassroomFilterMenu(
                classrooms: classrooms,
                selectedId: state.classroomFilterId,
                allLabel: l10n.teacherCalendarFilterClassroomAll,
                onChanged: (id) => bloc.add(TeacherCalendarClassroomFilterChanged(id)),
              ),
              const SizedBox(width: AppSpacing.s2),
            ],
            _kindChip(context, l10n.teacherCalendarFilterAll, TeacherCalendarKindFilter.all),
            _kindChip(context, l10n.teacherCalendarKindDue, TeacherCalendarKindFilter.due),
            _kindChip(context, l10n.teacherCalendarKindOpens, TeacherCalendarKindFilter.opens),
            _kindChip(context, l10n.teacherCalendarKindCloses, TeacherCalendarKindFilter.closes),
            _kindChip(context, l10n.teacherCalendarKindLive, TeacherCalendarKindFilter.live),
          ],
        ),
      ],
    );
  }
}

class _CalendarSearchField extends StatefulWidget {
  const _CalendarSearchField({
    required this.query,
    required this.hintText,
    required this.onChanged,
  });

  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<_CalendarSearchField> createState() => _CalendarSearchFieldState();
}

class _CalendarSearchFieldState extends State<_CalendarSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _CalendarSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: TeacherWebUi.webBody(context),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TeacherWebUi.metaMuted,
        prefixIcon: const Icon(Icons.search, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
      ),
    );
  }
}

class _ClassroomFilterMenu extends StatelessWidget {
  const _ClassroomFilterMenu({
    required this.classrooms,
    required this.selectedId,
    required this.allLabel,
    required this.onChanged,
  });

  final List<TeacherCalendarClassroomOption> classrooms;
  final String? selectedId;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedName = selectedId == null
        ? allLabel
        : classrooms.firstWhere((c) => c.id == selectedId, orElse: () => TeacherCalendarClassroomOption(id: '', name: allLabel)).name;

    return PopupMenuButton<String?>(
      tooltip: allLabel,
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text(allLabel, style: TeacherWebUi.webBody(context))),
        ...classrooms.map(
          (c) => PopupMenuItem(value: c.id, child: Text(c.name, style: TeacherWebUi.webBody(context))),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          color: AppColors.surfaceCard,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedName, style: TeacherWebUi.webCaption(context)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MonthScheduleBody extends StatelessWidget {
  const _MonthScheduleBody({required this.state});

  final TeacherCalendarState state;

  @override
  Widget build(BuildContext context) {
    final dayEvents = teacherCalendarEventsForDay(state.selectedDay, state.visibleEvents);
    final dayGroups = teacherCalendarGroupEvents(dayEvents);

    return TeacherResponsiveColumns(
      breakpoint: 960,
      left: _CalendarMonthGrid(
        displayedMonth: state.displayedMonth,
        selectedDay: state.selectedDay,
        events: state.visibleEvents,
        onPrev: () => context.read<TeacherCalendarBloc>().add(const TeacherCalendarPeriodShifted(-1)),
        onNext: () => context.read<TeacherCalendarBloc>().add(const TeacherCalendarPeriodShifted(1)),
        onDaySelected: (d) => context.read<TeacherCalendarBloc>().add(TeacherCalendarDaySelected(d)),
      ),
      right: _CalendarAgendaPanel(day: state.selectedDay, groups: dayGroups),
    );
  }
}

class _WeekScheduleBody extends StatelessWidget {
  const _WeekScheduleBody({required this.state});

  final TeacherCalendarState state;

  @override
  Widget build(BuildContext context) {
    final dayEvents = teacherCalendarEventsForDay(state.selectedDay, state.visibleEvents);
    final dayGroups = teacherCalendarGroupEvents(dayEvents);

    return TeacherResponsiveColumns(
      breakpoint: 960,
      left: _CalendarWeekGrid(
        weekStart: teacherCalendarWeekStart(state.selectedDay),
        selectedDay: state.selectedDay,
        events: state.visibleEvents,
        onPrev: () => context.read<TeacherCalendarBloc>().add(const TeacherCalendarPeriodShifted(-1)),
        onNext: () => context.read<TeacherCalendarBloc>().add(const TeacherCalendarPeriodShifted(1)),
        onDaySelected: (d) => context.read<TeacherCalendarBloc>().add(TeacherCalendarDaySelected(d)),
      ),
      right: _CalendarAgendaPanel(day: state.selectedDay, groups: dayGroups),
    );
  }
}

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.displayedMonth,
    required this.selectedDay,
    required this.events,
    required this.onPrev,
    required this.onNext,
    required this.onDaySelected,
  });

  final DateTime displayedMonth;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> events;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);
    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;
    final weekdayLabels = List.generate(7, (i) {
      final d = DateTime(2024, 1, 1 + i);
      return DateFormat.E(locale).format(d);
    });

    return Container(
      decoration: TeacherWebUi.panelDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PeriodHeader(
            title: DateFormat.yMMMM(locale).format(displayedMonth),
            onPrev: onPrev,
            onNext: onNext,
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: weekdayLabels
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(d, style: TeacherWebUi.webTableHead(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.s2),
          for (var row = 0; row < totalCells ~/ 7; row++)
            Row(
              children: List.generate(7, (col) {
                final cellIdx = row * 7 + col;
                final dayNum = cellIdx - startOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 56));
                }
                final day = DateTime(displayedMonth.year, displayedMonth.month, dayNum);
                return Expanded(
                  child: _CalendarDayCell(
                    day: day,
                    now: now,
                    selectedDay: selectedDay,
                    events: teacherCalendarEventsForDay(day, events),
                    onTap: () => onDaySelected(day),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _CalendarWeekGrid extends StatelessWidget {
  const _CalendarWeekGrid({
    required this.weekStart,
    required this.selectedDay,
    required this.events,
    required this.onPrev,
    required this.onNext,
    required this.onDaySelected,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> events;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final title = '${DateFormat.MMMd(locale).format(weekStart)} – ${DateFormat.MMMd(locale).format(weekEnd)}';

    return Container(
      decoration: TeacherWebUi.panelDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PeriodHeader(title: title, onPrev: onPrev, onNext: onNext),
          const SizedBox(height: AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final dayEvents = teacherCalendarEventsForDay(day, events);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  child: _CalendarWeekDayColumn(
                    day: day,
                    now: now,
                    selectedDay: selectedDay,
                    events: dayEvents,
                    onTap: () => onDaySelected(day),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.title, required this.onPrev, required this.onNext});

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 20),
          style: TeacherWebUi.compactHeaderIconStyle(),
        ),
        Expanded(
          child: Center(
            child: Text(title, style: TeacherWebUi.listTitle(context).copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
          style: TeacherWebUi.compactHeaderIconStyle(),
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.now,
    required this.selectedDay,
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final DateTime now;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayOnly = teacherCalendarDateOnly(day);
    final isToday = dayOnly == teacherCalendarDateOnly(now);
    final isSelected = dayOnly == teacherCalendarDateOnly(selectedDay);
    final count = teacherCalendarGroupEvents(events).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 56,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryTint
                : isToday
                    ? AppColors.accentTint.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.accent.withValues(alpha: 0.45)
                      : AppColors.outlineMuted,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.accentDark
                          : AppColors.textPrimary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 2),
                _DayEventBadge(count: count, kind: events.first['kind'] as String?),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarWeekDayColumn extends StatelessWidget {
  const _CalendarWeekDayColumn({
    required this.day,
    required this.now,
    required this.selectedDay,
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final DateTime now;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayOnly = teacherCalendarDateOnly(day);
    final isToday = dayOnly == teacherCalendarDateOnly(now);
    final isSelected = dayOnly == teacherCalendarDateOnly(selectedDay);
    final groups = teacherCalendarGroupEvents(events);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTint : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.accent.withValues(alpha: 0.45)
                      : AppColors.outlineMuted,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                DateFormat.E(locale).format(day),
                style: TeacherWebUi.webTableHead(context),
                textAlign: TextAlign.center,
              ),
              Text(
                '${day.day}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isToday ? AppColors.accentDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              if (groups.isEmpty)
                const SizedBox(height: 8)
              else
                ...groups.take(3).map((g) {
                  final primary = teacherCalendarPrimaryMilestone(g.milestones) ?? g.anchor;
                  final kind = primary['kind'] as String?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _CalendarKindStyle.color(kind),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  );
                }),
              if (groups.length > 3)
                Text(
                  '+${groups.length - 3}',
                  textAlign: TextAlign.center,
                  style: TeacherWebUi.webCaption(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayEventBadge extends StatelessWidget {
  const _DayEventBadge({required this.count, required this.kind});

  final int count;
  final String? kind;

  @override
  Widget build(BuildContext context) {
    final color = _CalendarKindStyle.color(kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _CalendarAgendaPanel extends StatelessWidget {
  const _CalendarAgendaPanel({required this.day, required this.groups});

  final DateTime day;
  final List<TeacherCalendarAssignmentGroup> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMMEEEEd(locale).format(day);
    final isToday = teacherCalendarDateOnly(day) == teacherCalendarDateOnly(DateTime.now());

    return Container(
      decoration: TeacherWebUi.panelDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.teacherCalendarAgendaTitle, style: TeacherWebUi.sectionTitle(context)),
                    const SizedBox(height: 4),
                    Text(dateLabel, style: TeacherWebUi.listTitle(context).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    l10n.teacherCalendarToday,
                    style: TeacherWebUi.webCaption(context).copyWith(
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(l10n.teacherCalendarGroupsOnDay(groups.length), style: TeacherWebUi.metaMuted),
          const SizedBox(height: AppSpacing.s4),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: TeacherEmptyCard(
                message: l10n.teacherCalendarNoDayEvents,
                icon: Icons.event_busy_outlined,
                actionLabel: l10n.teacherEmptyCalendarCta,
                onAction: () => context.push(TeacherExamsListPage.routePath),
              ),
            )
          else
            ...groups.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: _CalendarAssignmentGroupCard(group: g),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListScheduleBody extends StatelessWidget {
  const _ListScheduleBody({required this.state});

  final TeacherCalendarState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grouped = _groupListAssignmentGroups(state.visibleEvents);

    if (state.visibleEvents.isEmpty) {
      return Center(
        child: TeacherEmptyCard(
          message: l10n.teacherCalendarEmpty,
          icon: Icons.event_outlined,
          actionLabel: l10n.teacherEmptyCalendarCta,
          onAction: () => context.push(TeacherExamsListPage.routePath),
        ),
      );
    }

    return ListView(
      padding: TeacherWebUi.pageScrollPadding(context),
      children: [
        if (grouped[_ListSection.today]!.isNotEmpty) ...[
          _ListSectionHeader(title: l10n.teacherCalendarSectionToday),
          ...grouped[_ListSection.today]!.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: _CalendarAssignmentGroupCard(group: g, showPrimaryDate: true),
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
        ],
        if (grouped[_ListSection.upcoming]!.isNotEmpty) ...[
          _ListSectionHeader(title: l10n.teacherCalendarSectionUpcoming),
          ...grouped[_ListSection.upcoming]!.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: _CalendarAssignmentGroupCard(group: g, showPrimaryDate: true),
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
        ],
        if (grouped[_ListSection.past]!.isNotEmpty) ...[
          _ListSectionHeader(title: l10n.teacherCalendarSectionPast, muted: true),
          ...grouped[_ListSection.past]!.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: Opacity(
                opacity: 0.65,
                child: _CalendarAssignmentGroupCard(group: g, showPrimaryDate: true),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ListSectionHeader extends StatelessWidget {
  const _ListSectionHeader({required this.title, this.muted = false});

  final String title;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Text(
        title,
        style: TeacherWebUi.sectionTitle(context).copyWith(
          color: muted ? AppColors.textMuted : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CalendarAssignmentGroupCard extends StatelessWidget {
  const _CalendarAssignmentGroupCard({required this.group, this.showPrimaryDate = false});

  final TeacherCalendarAssignmentGroup group;
  final bool showPrimaryDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final anchor = group.anchor;
    final primary = teacherCalendarPrimaryMilestone(group.milestones) ?? anchor;
    final primaryKind = primary['kind'] as String?;
    final color = _CalendarKindStyle.color(primaryKind);
    final bg = _CalendarKindStyle.bg(primaryKind);
    final title = group.examTitle(anchor);
    final classroom = (anchor['classroomName'] as String?)?.trim() ?? '';
    final mode = TeacherGradingHubLabels.modeLabel(l10n, anchor['mode'] as String?);
    final primaryAt = teacherCalendarEventAt(primary);
    final relative = primaryAt != null ? teacherCalendarRelativeTimeLabel(l10n, primaryAt) : '';
    final dateStr = showPrimaryDate && primaryAt != null ? DateFormat.MMMd(locale).format(primaryAt) : '';
    final metaParts = [if (classroom.isNotEmpty) classroom, mode, if (dateStr.isNotEmpty) dateStr]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => teacherCalendarNavigateToGroup(context, group),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(_CalendarKindStyle.icon(primaryKind), size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (relative.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              relative,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TeacherWebUi.listTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (metaParts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          metaParts,
                          style: TeacherWebUi.webCaption(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s2),
                    _MilestoneTimeline(l10n: l10n, milestones: group.milestones),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneTimeline extends StatelessWidget {
  const _MilestoneTimeline({required this.l10n, required this.milestones});

  final AppLocalizations l10n;
  final List<Map<String, dynamic>> milestones;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: milestones.map((m) {
        final kind = m['kind'] as String?;
        final color = _CalendarKindStyle.color(kind);
        final at = teacherCalendarEventAt(m);
        final time = at != null ? DateFormat.jm(locale).format(at) : '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            '${_CalendarKindStyle.label(l10n, kind)}${time.isNotEmpty ? ' $time' : ''}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        );
      }).toList(),
    );
  }
}
