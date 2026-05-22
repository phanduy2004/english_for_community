import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TeacherCalendarPage extends StatefulWidget {
  const TeacherCalendarPage({super.key});

  static const String routePath = '/teacher/calendar';
  static const String routeName = 'TeacherCalendarPage';

  @override
  State<TeacherCalendarPage> createState() => _TeacherCalendarPageState();
}

class _TeacherCalendarPageState extends State<TeacherCalendarPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];
  bool _monthView = true;
  late DateTime _displayedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final from = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    final to = DateTime(_displayedMonth.year, _displayedMonth.month + 3, 1);
    final r = await getIt<TeacherExamRepository>().getTeacherCalendarEvents(
      from: from.toUtc().toIso8601String(),
      to: to.toUtc().toIso8601String(),
    );
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (d) {
        final list = (d['events'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _events = list;
          _loading = false;
        });
      },
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month);
      _selectedDay = now;
    });
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
      _selectedDay = null;
    });
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    return _events.where((e) {
      final at = DateTime.tryParse(e['at'] as String? ?? '')?.toLocal();
      if (at == null) return false;
      return at.year == day.year && at.month == day.month && at.day == day.day;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _eventsGroupedByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in _events) {
      final at = DateTime.tryParse(e['at'] as String? ?? '')?.toLocal();
      if (at == null) continue;
      final key = at.toIso8601String().substring(0, 10);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final useListScroll = !_loading && _error == null && !_monthView;

    return TeacherPageScaffold(
      scrollable: !useListScroll,
      title: l10n.teacherNavCalendar,
      breadcrumbs: [
        TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(label: l10n.teacherNavCalendar),
      ],
      actions: [
        TextButton(onPressed: _goToToday, child: Text(l10n.teacherCalendarToday)),
        const SizedBox(width: AppSpacing.s2),
        _ViewToggle(
          monthView: _monthView,
          onChanged: (v) => setState(() {
            _monthView = v;
            _selectedDay = null;
          }),
        ),
        const SizedBox(width: AppSpacing.s2),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_outlined, size: 20)),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TeacherWebUi.webBody(context)),
                      const SizedBox(height: AppSpacing.s5),
                      TeacherRetryButton(onPressed: _load),
                    ],
                  ),
                )
              : _monthView
                  ? _MonthBody(
                      displayedMonth: _displayedMonth,
                      selectedDay: _selectedDay,
                      events: _events,
                      onPrevMonth: _prevMonth,
                      onNextMonth: _nextMonth,
                      onDaySelected: (d) => setState(() => _selectedDay = d),
                      eventsForDay: _eventsForDay,
                    )
                  : _ListBody(grouped: _eventsGroupedByDate()),
    );
  }
}

// ── View toggle button ─────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.monthView, required this.onChanged});

  final bool monthView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab(context, Icons.grid_view_outlined, l10n.teacherCalendarViewMonth, monthView, () => onChanged(true)),
          _tab(context, Icons.view_list_outlined, l10n.teacherCalendarViewList, !monthView, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip - 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? AppColors.onPrimary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Month view body ────────────────────────────────────────────────────────────

class _MonthBody extends StatelessWidget {
  const _MonthBody({
    required this.displayedMonth,
    required this.selectedDay,
    required this.events,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDaySelected,
    required this.eventsForDay,
  });

  final DateTime displayedMonth;
  final DateTime? selectedDay;
  final List<Map<String, dynamic>> events;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;
  final List<Map<String, dynamic>> Function(DateTime) eventsForDay;

  @override
  Widget build(BuildContext context) {
    final selectedEvents = selectedDay != null ? eventsForDay(selectedDay!) : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
          child: _CalendarGrid(
            displayedMonth: displayedMonth,
            selectedDay: selectedDay,
            eventsForDay: eventsForDay,
            onPrevMonth: onPrevMonth,
            onNextMonth: onNextMonth,
            onDaySelected: onDaySelected,
          ),
        ),
        if (selectedDay != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Padding(
            padding: EdgeInsets.zero,
            child: _DayEventPanel(
              day: selectedDay!,
              events: selectedEvents,
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
        ],
      ],
    );
  }
}

// ── Calendar grid ──────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.displayedMonth,
    required this.selectedDay,
    required this.eventsForDay,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDaySelected,
  });

  final DateTime displayedMonth;
  final DateTime? selectedDay;
  final List<Map<String, dynamic>> Function(DateTime) eventsForDay;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    // weekday: Mon=1...Sun=7, we want Mon=0 offset
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);
    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

    return Container(
      decoration: TeacherWebUi.cardDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation header
          Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat.yMMMM().format(displayedMonth),
                    style: TeacherWebUi.listTitle(context).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          // Weekday headers
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.s2),
          // Day cells
          for (var row = 0; row < totalCells ~/ 7; row++) ...[
            Row(
              children: List.generate(7, (col) {
                final cellIdx = row * 7 + col;
                final dayNum = cellIdx - startOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 52));
                }
                final day = DateTime(displayedMonth.year, displayedMonth.month, dayNum);
                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                final isSelected = selectedDay != null &&
                    day.year == selectedDay!.year &&
                    day.month == selectedDay!.month &&
                    day.day == selectedDay!.day;
                final dayEvents = eventsForDay(day);

                return Expanded(
                  child: GestureDetector(
                    onTap: dayEvents.isNotEmpty ? () => onDaySelected(day) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: 52,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryTint
                            : isToday
                                ? AppColors.accentTint
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: isSelected
                            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DayNumber(day: dayNum, isToday: isToday, isSelected: isSelected),
                          const SizedBox(height: 2),
                          _EventDots(events: dayEvents),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({required this.day, required this.isToday, required this.isSelected});

  final int day;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (isToday) {
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$day',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.onAccent,
          ),
        ),
      );
    }
    return Text(
      '$day',
      style: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }
}

class _EventDots extends StatelessWidget {
  const _EventDots({required this.events});

  final List<Map<String, dynamic>> events;

  static Color _kindColor(String? kind) {
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

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox(height: 6);
    final shown = events.take(3).toList();
    final overflow = events.length - shown.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...shown.map((e) => Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _kindColor(e['kind'] as String?),
                shape: BoxShape.circle,
              ),
            )),
        if (overflow > 0)
          Text('+$overflow', style: const TextStyle(fontSize: 7, color: AppColors.textMuted)),
      ],
    );
  }
}

// ── Day event panel (shown below grid when day tapped) ───────────────────────

class _DayEventPanel extends StatelessWidget {
  const _DayEventPanel({required this.day, required this.events});

  final DateTime day;
  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = DateFormat.yMMMMEEEEd().format(day);

    return Container(
      decoration: TeacherWebUi.cardDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TeacherWebUi.listTitle(context).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.s3),
          if (events.isEmpty)
            Text(l10n.teacherCalendarNoDayEvents, style: TeacherWebUi.webBody(context))
          else
            ...events.map((e) => _EventTile(event: e)),
        ],
      ),
    );
  }
}

// ── List view body ─────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  const _ListBody({required this.grouped});

  final Map<String, List<Map<String, dynamic>>> grouped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: TeacherEmptyCard(message: l10n.teacherCalendarEmpty, icon: Icons.event_outlined),
        ),
      );
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ListView.builder(
      padding: TeacherWebUi.pageScrollPadding(context),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final key = grouped.keys.elementAt(i);
        final dayEvents = grouped[key]!;
        final dt = DateTime.tryParse(key) ?? today;
        final isPast = dt.isBefore(today);
        return Opacity(
          opacity: isPast ? 0.55 : 1.0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isPast ? AppColors.textMuted : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMMEEEEd().format(dt),
                        style: TeacherWebUi.listTitle(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ...dayEvents.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                      child: _EventTile(event: e),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Individual event tile ──────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Map<String, dynamic> event;

  static Color _kindColor(String? kind) {
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

  static Color _kindBg(String? kind) {
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

  String _kindLabel(BuildContext context, String? kind) {
    final l10n = context.l10n;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = event['kind'] as String?;
    final color = _kindColor(kind);
    final bg = _kindBg(kind);
    final at = DateTime.tryParse(event['at'] as String? ?? '')?.toLocal();
    final timeStr = at != null ? DateFormat.jm().format(at) : '';
    final aid = event['assignmentId'] as String? ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: aid.isNotEmpty ? () => context.push('${TeacherExamGradingPage.routePath}/$aid') : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            _kindLabel(context, kind),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TeacherWebUi.metaMuted.copyWith(fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (event['title'] as String?) ?? '—',
                      style: TeacherWebUi.listTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (aid.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s3),
                  child: TextButton(
                    onPressed: () => context.push('${TeacherExamGradingPage.routePath}/$aid'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.teacherCalendarGoToAssignment, style: const TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
