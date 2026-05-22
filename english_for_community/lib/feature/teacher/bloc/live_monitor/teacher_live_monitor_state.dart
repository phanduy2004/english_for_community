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
  });

  final TeacherLiveMonitorStatus status;
  final String? errorMessage;
  final List<Map<String, dynamic>> students;
  final Map<String, dynamic> summary;
  final TeacherLiveMonitorFilter filter;

  factory TeacherLiveMonitorState.initial() =>
      const TeacherLiveMonitorState(status: TeacherLiveMonitorStatus.initial);

  List<Map<String, dynamic>> get visibleStudents {
    switch (filter) {
      case TeacherLiveMonitorFilter.inProgress:
        return students.where((s) => s['status'] == 'in_progress').toList();
      case TeacherLiveMonitorFilter.submitted:
        return students
            .where((s) => ['submitted', 'expired', 'void'].contains(s['status']))
            .toList();
      case TeacherLiveMonitorFilter.flagged:
        return students
            .where((s) => s['integrityRiskLevel'] == 'high' || s['integrityRiskLevel'] == 'medium')
            .toList();
      case TeacherLiveMonitorFilter.all:
        return students;
    }
  }

  TeacherLiveMonitorState copyWith({
    TeacherLiveMonitorStatus? status,
    String? errorMessage,
    List<Map<String, dynamic>>? students,
    Map<String, dynamic>? summary,
    TeacherLiveMonitorFilter? filter,
    bool clearError = false,
  }) {
    return TeacherLiveMonitorState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      students: students ?? this.students,
      summary: summary ?? this.summary,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, students, summary, filter];
}
