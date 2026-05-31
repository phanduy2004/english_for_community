import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_event.dart';
import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherCalendarBloc extends Bloc<TeacherCalendarEvent, TeacherCalendarState> {
  TeacherCalendarBloc({required this.repository}) : super(TeacherCalendarState.initial()) {
    on<TeacherCalendarLoadRequested>(_onLoad);
    on<TeacherCalendarViewModeChanged>(_onViewMode);
    on<TeacherCalendarGoToToday>(_onToday);
    on<TeacherCalendarPrevMonth>(_onPrev);
    on<TeacherCalendarNextMonth>(_onNext);
    on<TeacherCalendarDaySelected>(_onDaySelected);
  }

  final TeacherExamRepository repository;

  Future<void> _onLoad(
    TeacherCalendarLoadRequested event,
    Emitter<TeacherCalendarState> emit,
  ) async {
    emit(state.copyWith(status: TeacherCalendarStatus.loading, clearError: true));
    final from = DateTime(state.displayedMonth.year, state.displayedMonth.month - 1, 1);
    final to = DateTime(state.displayedMonth.year, state.displayedMonth.month + 3, 1);
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
    emit(state.copyWith(monthView: event.monthView, clearSelectedDay: true));
  }

  void _onToday(
    TeacherCalendarGoToToday event,
    Emitter<TeacherCalendarState> emit,
  ) {
    final now = DateTime.now();
    emit(state.copyWith(
      displayedMonth: DateTime(now.year, now.month),
      selectedDay: now,
    ));
    add(const TeacherCalendarLoadRequested());
  }

  void _onPrev(
    TeacherCalendarPrevMonth event,
    Emitter<TeacherCalendarState> emit,
  ) {
    emit(state.copyWith(
      displayedMonth: DateTime(state.displayedMonth.year, state.displayedMonth.month - 1),
      clearSelectedDay: true,
    ));
    add(const TeacherCalendarLoadRequested());
  }

  void _onNext(
    TeacherCalendarNextMonth event,
    Emitter<TeacherCalendarState> emit,
  ) {
    emit(state.copyWith(
      displayedMonth: DateTime(state.displayedMonth.year, state.displayedMonth.month + 1),
      clearSelectedDay: true,
    ));
    add(const TeacherCalendarLoadRequested());
  }

  void _onDaySelected(
    TeacherCalendarDaySelected event,
    Emitter<TeacherCalendarState> emit,
  ) {
    emit(state.copyWith(selectedDay: event.day));
  }
}
