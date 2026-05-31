import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:equatable/equatable.dart';

enum TeacherLiveMonitorStatus { initial, loading, success, error }

class TeacherLiveMonitorState extends Equatable {
  const TeacherLiveMonitorState({
    required this.status,
    this.errorMessage,
    this.students = const [],
    this.summary = const {},
    this.filter = TeacherLiveMonitorFilter.all,
    this.visibleStudents = const [],
    this.studentsByUserId = const {},
    this.dataRevision = 0,
  });

  final TeacherLiveMonitorStatus status;
  final String? errorMessage;
  final List<Map<String, dynamic>> students;
  final Map<String, dynamic> summary;
  final TeacherLiveMonitorFilter filter;
  /// Pre-filtered list — avoids re-filtering on every [BlocBuilder] rebuild.
  final List<Map<String, dynamic>> visibleStudents;
  final Map<String, Map<String, dynamic>> studentsByUserId;
  final int dataRevision;

  factory TeacherLiveMonitorState.initial() =>
      const TeacherLiveMonitorState(status: TeacherLiveMonitorStatus.initial);

  TeacherLiveMonitorState copyWith({
    TeacherLiveMonitorStatus? status,
    String? errorMessage,
    List<Map<String, dynamic>>? students,
    Map<String, dynamic>? summary,
    TeacherLiveMonitorFilter? filter,
    List<Map<String, dynamic>>? visibleStudents,
    Map<String, Map<String, dynamic>>? studentsByUserId,
    int? dataRevision,
    bool clearError = false,
  }) {
    return TeacherLiveMonitorState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      students: students ?? this.students,
      summary: summary ?? this.summary,
      filter: filter ?? this.filter,
      visibleStudents: visibleStudents ?? this.visibleStudents,
      studentsByUserId: studentsByUserId ?? this.studentsByUserId,
      dataRevision: dataRevision ?? this.dataRevision,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        students,
        summary,
        filter,
        visibleStudents,
        studentsByUserId,
        dataRevision,
      ];
}
