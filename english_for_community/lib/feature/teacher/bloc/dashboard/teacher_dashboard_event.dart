import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_ui.dart';
import 'package:equatable/equatable.dart';

abstract class TeacherDashboardEvent extends Equatable {
  const TeacherDashboardEvent();

  @override
  List<Object?> get props => [];
}

class TeacherDashboardLoadRequested extends TeacherDashboardEvent {
  const TeacherDashboardLoadRequested();
}

class TeacherDashboardCloseAssignmentRequested extends TeacherDashboardEvent {
  const TeacherDashboardCloseAssignmentRequested(this.assignmentId);

  final String assignmentId;

  @override
  List<Object?> get props => [assignmentId];
}

class TeacherDashboardRotatePublicLinkRequested extends TeacherDashboardEvent {
  const TeacherDashboardRotatePublicLinkRequested(this.assignmentId);

  final String assignmentId;

  @override
  List<Object?> get props => [assignmentId];
}

class TeacherDashboardSearchQueryChanged extends TeacherDashboardEvent {
  const TeacherDashboardSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class TeacherDashboardAssignmentFilterChanged extends TeacherDashboardEvent {
  const TeacherDashboardAssignmentFilterChanged(this.filter);

  final TeacherDashboardAssignmentFilter filter;

  @override
  List<Object?> get props => [filter];
}

class TeacherDashboardClassroomFilterChanged extends TeacherDashboardEvent {
  const TeacherDashboardClassroomFilterChanged(this.classroomId);

  final String? classroomId;

  @override
  List<Object?> get props => [classroomId];
}
