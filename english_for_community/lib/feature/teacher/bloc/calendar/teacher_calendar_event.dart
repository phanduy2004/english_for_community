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
  const TeacherCalendarViewModeChanged(this.monthView);

  final bool monthView;

  @override
  List<Object?> get props => [monthView];
}

class TeacherCalendarGoToToday extends TeacherCalendarEvent {
  const TeacherCalendarGoToToday();
}

class TeacherCalendarPrevMonth extends TeacherCalendarEvent {
  const TeacherCalendarPrevMonth();
}

class TeacherCalendarNextMonth extends TeacherCalendarEvent {
  const TeacherCalendarNextMonth();
}

class TeacherCalendarDaySelected extends TeacherCalendarEvent {
  const TeacherCalendarDaySelected(this.day);

  final DateTime day;

  @override
  List<Object?> get props => [day];
}
