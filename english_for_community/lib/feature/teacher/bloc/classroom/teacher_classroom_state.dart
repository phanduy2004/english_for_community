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
  });

  final TeacherClassroomStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? classroom;
  final List<dynamic> assignments;
  final List<dynamic> members;
  final bool mutationInProgress;
  final bool settingsSaving;
  final bool archived;

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
      ];
}
