import 'package:equatable/equatable.dart';

enum TeacherCalendarStatus { initial, loading, success, error }

class TeacherCalendarState extends Equatable {
  const TeacherCalendarState({
    required this.status,
    this.errorMessage,
    this.events = const [],
    this.monthView = true,
    required this.displayedMonth,
    this.selectedDay,
  });

  final TeacherCalendarStatus status;
  final String? errorMessage;
  final List<Map<String, dynamic>> events;
  final bool monthView;
  final DateTime displayedMonth;
  final DateTime? selectedDay;

  factory TeacherCalendarState.initial() {
    final now = DateTime.now();
    return TeacherCalendarState(
      status: TeacherCalendarStatus.initial,
      displayedMonth: DateTime(now.year, now.month),
    );
  }

  TeacherCalendarState copyWith({
    TeacherCalendarStatus? status,
    String? errorMessage,
    List<Map<String, dynamic>>? events,
    bool? monthView,
    DateTime? displayedMonth,
    DateTime? selectedDay,
    bool clearSelectedDay = false,
    bool clearError = false,
  }) {
    return TeacherCalendarState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      events: events ?? this.events,
      monthView: monthView ?? this.monthView,
      displayedMonth: displayedMonth ?? this.displayedMonth,
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, events, monthView, displayedMonth, selectedDay];
}
