import 'package:equatable/equatable.dart';

enum TeacherClassroomStatus { initial, loading, success, error }

class TeacherClassroomState extends Equatable {
  const TeacherClassroomState({
    required this.status,
    this.errorMessage,
    this.classroom,
    this.assignments = const [],
    this.members = const [],
    this.mutationInProgress = false,
    this.settingsSaving = false,
    this.archived = false,
    this.assignmentSegment = 0,
    this.assignmentsReloading = false,
    this.activityRows = const [],
    this.activityReloading = false,
  });

  final TeacherClassroomStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? classroom;
  final List<dynamic> assignments;
  final List<dynamic> members;
  final bool mutationInProgress;
  final bool settingsSaving;
  final bool archived;
  final int assignmentSegment;
  final bool assignmentsReloading;
  final List<dynamic> activityRows;
  final bool activityReloading;

  factory TeacherClassroomState.initial() =>
      const TeacherClassroomState(status: TeacherClassroomStatus.initial);

  TeacherClassroomState copyWith({
    TeacherClassroomStatus? status,
    String? errorMessage,
    Map<String, dynamic>? classroom,
    List<dynamic>? assignments,
    List<dynamic>? members,
    bool? mutationInProgress,
    bool? settingsSaving,
    bool? archived,
    int? assignmentSegment,
    bool? assignmentsReloading,
    List<dynamic>? activityRows,
    bool? activityReloading,
    bool clearError = false,
  }) {
    return TeacherClassroomState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      classroom: classroom ?? this.classroom,
      assignments: assignments ?? this.assignments,
      members: members ?? this.members,
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      settingsSaving: settingsSaving ?? this.settingsSaving,
      archived: archived ?? this.archived,
      assignmentSegment: assignmentSegment ?? this.assignmentSegment,
      assignmentsReloading: assignmentsReloading ?? this.assignmentsReloading,
      activityRows: activityRows ?? this.activityRows,
      activityReloading: activityReloading ?? this.activityReloading,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        classroom,
        assignments,
        members,
        mutationInProgress,
        settingsSaving,
        archived,
        assignmentSegment,
        assignmentsReloading,
        activityRows,
        activityReloading,
      ];
}
