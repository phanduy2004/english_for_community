import 'package:equatable/equatable.dart';

abstract class TeacherClassroomEvent extends Equatable {
  const TeacherClassroomEvent();

  @override
  List<Object?> get props => [];
}

class TeacherClassroomLoadRequested extends TeacherClassroomEvent {
  const TeacherClassroomLoadRequested({this.silent = false});

  /// When true, refresh data without showing the full-page loading indicator.
  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class TeacherClassroomSaveSettingsRequested extends TeacherClassroomEvent {
  const TeacherClassroomSaveSettingsRequested({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;

  @override
  List<Object?> get props => [name, description];
}

class TeacherClassroomApproveMemberRequested extends TeacherClassroomEvent {
  const TeacherClassroomApproveMemberRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class TeacherClassroomRejectMemberRequested extends TeacherClassroomEvent {
  const TeacherClassroomRejectMemberRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class TeacherClassroomRemoveMemberRequested extends TeacherClassroomEvent {
  const TeacherClassroomRemoveMemberRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class TeacherClassroomRotateInviteRequested extends TeacherClassroomEvent {
  const TeacherClassroomRotateInviteRequested();
}

class TeacherClassroomArchiveRequested extends TeacherClassroomEvent {
  const TeacherClassroomArchiveRequested();
}

class TeacherClassroomDeleteAssignmentRequested extends TeacherClassroomEvent {
  const TeacherClassroomDeleteAssignmentRequested(this.assignmentId);

  final String assignmentId;

  @override
  List<Object?> get props => [assignmentId];
}

class TeacherClassroomCloseAssignmentRequested extends TeacherClassroomEvent {
  const TeacherClassroomCloseAssignmentRequested(this.assignmentId);

  final String assignmentId;

  @override
  List<Object?> get props => [assignmentId];
}

class TeacherClassroomAssignmentSegmentChanged extends TeacherClassroomEvent {
  const TeacherClassroomAssignmentSegmentChanged(this.segment);

  final int segment;

  @override
  List<Object?> get props => [segment];
}

class TeacherClassroomAssignmentsReloadRequested extends TeacherClassroomEvent {
  const TeacherClassroomAssignmentsReloadRequested();
}

class TeacherClassroomActivityReloadRequested extends TeacherClassroomEvent {
  const TeacherClassroomActivityReloadRequested();
}
