import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_event.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_filter.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherCalendarBloc extends Bloc<TeacherCalendarEvent, TeacherCalendarState> {
  TeacherCalendarBloc({required this.repository}) : super(TeacherCalendarState.initial()) {
    on<TeacherCalendarLoadRequested>(_onLoad);
    on<TeacherCalendarViewModeChanged>(_onViewMode);
    on<TeacherCalendarGoToToday>(_onToday);
    on<TeacherCalendarPeriodShifted>(_onPeriodShift);
    on<TeacherCalendarDaySelected>(_onDaySelected);
    on<TeacherCalendarKindFilterChanged>(_onKindFilter);
    on<TeacherCalendarClassroomFilterChanged>(_onClassroomFilter);
    on<TeacherCalendarSearchChanged>(_onSearch);
    on<TeacherCalendarKpiTapped>(_onKpiTapped);
  }

  final TeacherExamRepository repository;

  Future<void> _onLoad(
    TeacherCalendarLoadRequested event,
    Emitter<TeacherCalendarState> emit,
  ) async {
    emit(state.copyWith(status: TeacherCalendarStatus.loading, clearError: true));
    final anchor = state.viewMode == TeacherCalendarViewMode.week
        ? teacherCalendarWeekStart(state.selectedDay)
        : state.displayedMonth;
    final from = DateTime(anchor.year, anchor.month - 1, 1);
    final to = DateTime(anchor.year, anchor.month + 3, 1);
    final r = await repository.getTeacherCalendarEvents(
      from: from.toUtc().toIso8601String(),
      to: to.toUtc().toIso8601String(),
    );
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherCalendarStatus.error,
        errorMessage: f.message,
      )),
      (d) {
        final list = (d['events'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        emit(state.copyWith(
          status: TeacherCalendarStatus.success,
          events: list,
        ));
      },
    );
  }

  void _onViewMode(
    TeacherCalendarViewModeChanged event,
    Emitter<TeacherCalendarState> emit,
  ) {
    emit(state.copyWith(viewMode: event.viewMode));
  }

  void _onToday(
    TeacherCalendarGoToToday event,
    Emitter<TeacherCalendarState> emit,
  ) {
    final now = DateTime.now();
    emit(state.copyWith(
      displayedMonth: DateTime(now.year, now.month),
      selectedDay: DateTime(now.year, now.month, now.day),
    ));
    add(const TeacherCalendarLoadRequested());
  }

  void _onPeriodShift(
    TeacherCalendarPeriodShifted event,
    Emitter<TeacherCalendarState> emit,
  ) {
    switch (state.viewMode) {
      case TeacherCalendarViewMode.month:
        emit(state.copyWith(
          displayedMonth: DateTime(
            state.displayedMonth.year,
            state.displayedMonth.month + event.delta,
          ),
        ));
        add(const TeacherCalendarLoadRequested());
      case TeacherCalendarViewMode.week:
        final weekStart = teacherCalendarWeekStart(state.selectedDay);
        final shifted = weekStart.add(Duration(days: 7 * event.delta));
        emit(state.copyWith(
          selectedDay: shifted,
          displayedMonth: DateTime(shifted.year, shifted.month),
        ));
        add(const TeacherCalendarLoadRequested());
      case TeacherCalendarViewMode.list:
        break;
    }
  }

  void _onDaySelected(
    TeacherCalendarDaySelected event,
    Emitter<TeacherCalendarState> emit,
  ) {
    final d = event.day;
    emit(state.copyWith(
      selectedDay: DateTime(d.year, d.month, d.day),
      displayedMonth: DateTime(d.year, d.month),
    ));
  }

  void _onKindFilter(
    TeacherCalendarKindFilterChanged event,
    Emitter<TeacherCalendarState> emit,
  ) {
    if (event.filter == state.kindFilter) return;
    emit(state.copyWith(kindFilter: event.filter));
  }

  void _onClassroomFilter(
    TeacherCalendarClassroomFilterChanged event,
    Emitter<TeacherCalendarState> emit,
  ) {
    if (event.classroomId == state.classroomFilterId) return;
    emit(state.copyWith(
      classroomFilterId: event.classroomId,
      clearClassroomFilter: event.classroomId == null || event.classroomId!.isEmpty,
    ));
  }

  void _onSearch(
    TeacherCalendarSearchChanged event,
    Emitter<TeacherCalendarState> emit,
  ) {
    if (event.query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onKpiTapped(
    TeacherCalendarKpiTapped event,
    Emitter<TeacherCalendarState> emit,
  ) {
    emit(state.copyWith(
      kindFilter: event.filter,
      viewMode: TeacherCalendarViewMode.list,
    ));
  }
}
