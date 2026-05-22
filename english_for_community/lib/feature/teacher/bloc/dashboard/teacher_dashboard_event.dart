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
