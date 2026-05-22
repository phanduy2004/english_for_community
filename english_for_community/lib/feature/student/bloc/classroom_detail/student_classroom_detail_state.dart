import 'package:equatable/equatable.dart';

enum StudentClassroomDetailStatus { initial, loading, success, error }

class StudentClassroomDetailState extends Equatable {
  const StudentClassroomDetailState({
    required this.status,
    this.errorMessage,
    this.classroom,
    this.assignments = const [],
  });

  final StudentClassroomDetailStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? classroom;
  final List<dynamic> assignments;

  factory StudentClassroomDetailState.initial() =>
      const StudentClassroomDetailState(status: StudentClassroomDetailStatus.initial);

  StudentClassroomDetailState copyWith({
    StudentClassroomDetailStatus? status,
    String? errorMessage,
    Map<String, dynamic>? classroom,
    List<dynamic>? assignments,
    bool clearError = false,
  }) {
    return StudentClassroomDetailState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      classroom: classroom ?? this.classroom,
      assignments: assignments ?? this.assignments,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, classroom, assignments];
}
