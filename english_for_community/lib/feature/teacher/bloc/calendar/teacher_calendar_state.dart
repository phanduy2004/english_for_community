import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_filter.dart';
import 'package:equatable/equatable.dart';

enum TeacherCalendarStatus { initial, loading, success, error }

class TeacherCalendarState extends Equatable {
  const TeacherCalendarState({
    required this.status,
    this.errorMessage,
    this.events = const [],
    this.viewMode = TeacherCalendarViewMode.month,
    required this.displayedMonth,
    required this.selectedDay,
    this.kindFilter = TeacherCalendarKindFilter.all,
    this.classroomFilterId,
    this.searchQuery = '',
  });

  final TeacherCalendarStatus status;
  final String? errorMessage;
  final List<Map<String, dynamic>> events;
  final TeacherCalendarViewMode viewMode;
  final DateTime displayedMonth;
  final DateTime selectedDay;
  final TeacherCalendarKindFilter kindFilter;
  final String? classroomFilterId;
  final String searchQuery;

  List<Map<String, dynamic>> get visibleEvents => teacherCalendarVisibleEvents(
        events,
        kindFilter: kindFilter,
        classroomId: classroomFilterId,
        searchQuery: searchQuery,
      );

  List<TeacherCalendarClassroomOption> get classroomOptions =>
      teacherCalendarClassroomOptions(events);

  factory TeacherCalendarState.initial() {
    final now = DateTime.now();
    return TeacherCalendarState(
      status: TeacherCalendarStatus.initial,
      displayedMonth: DateTime(now.year, now.month),
      selectedDay: DateTime(now.year, now.month, now.day),
    );
  }

  TeacherCalendarState copyWith({
    TeacherCalendarStatus? status,
    String? errorMessage,
    List<Map<String, dynamic>>? events,
    TeacherCalendarViewMode? viewMode,
    DateTime? displayedMonth,
    DateTime? selectedDay,
    TeacherCalendarKindFilter? kindFilter,
    String? classroomFilterId,
    String? searchQuery,
    bool clearError = false,
    bool clearClassroomFilter = false,
  }) {
    return TeacherCalendarState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      events: events ?? this.events,
      viewMode: viewMode ?? this.viewMode,
      displayedMonth: displayedMonth ?? this.displayedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      kindFilter: kindFilter ?? this.kindFilter,
      classroomFilterId:
          clearClassroomFilter ? null : (classroomFilterId ?? this.classroomFilterId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        events,
        viewMode,
        displayedMonth,
        selectedDay,
        kindFilter,
        classroomFilterId,
        searchQuery,
      ];
}
