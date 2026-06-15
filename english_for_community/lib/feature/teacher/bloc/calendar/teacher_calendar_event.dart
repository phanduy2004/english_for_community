import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_filter.dart';
import 'package:equatable/equatable.dart';

abstract class TeacherCalendarEvent extends Equatable {
  const TeacherCalendarEvent();

  @override
  List<Object?> get props => [];
}

class TeacherCalendarLoadRequested extends TeacherCalendarEvent {
  const TeacherCalendarLoadRequested();
}

class TeacherCalendarViewModeChanged extends TeacherCalendarEvent {
  const TeacherCalendarViewModeChanged(this.viewMode);

  final TeacherCalendarViewMode viewMode;

  @override
  List<Object?> get props => [viewMode];
}

class TeacherCalendarGoToToday extends TeacherCalendarEvent {
  const TeacherCalendarGoToToday();
}

/// Previous period: month or week depending on [viewMode].
class TeacherCalendarPeriodShifted extends TeacherCalendarEvent {
  const TeacherCalendarPeriodShifted(this.delta);

  final int delta;

  @override
  List<Object?> get props => [delta];
}

class TeacherCalendarDaySelected extends TeacherCalendarEvent {
  const TeacherCalendarDaySelected(this.day);

  final DateTime day;

  @override
  List<Object?> get props => [day];
}

class TeacherCalendarKindFilterChanged extends TeacherCalendarEvent {
  const TeacherCalendarKindFilterChanged(this.filter);

  final TeacherCalendarKindFilter filter;

  @override
  List<Object?> get props => [filter];
}

class TeacherCalendarClassroomFilterChanged extends TeacherCalendarEvent {
  const TeacherCalendarClassroomFilterChanged(this.classroomId);

  final String? classroomId;

  @override
  List<Object?> get props => [classroomId];
}

class TeacherCalendarSearchChanged extends TeacherCalendarEvent {
  const TeacherCalendarSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class TeacherCalendarKpiTapped extends TeacherCalendarEvent {
  const TeacherCalendarKpiTapped(this.filter);

  final TeacherCalendarKindFilter filter;

  @override
  List<Object?> get props => [filter];
}
