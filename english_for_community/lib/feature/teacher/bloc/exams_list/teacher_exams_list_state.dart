import 'package:equatable/equatable.dart';

enum TeacherExamsListStatus { initial, loading, success, error }

class TeacherExamsListState extends Equatable {
  const TeacherExamsListState({
    required this.status,
    this.errorMessage,
    this.exams = const [],
    this.mutationInProgress = false,
  });

  final TeacherExamsListStatus status;
  final String? errorMessage;
  final List<dynamic> exams;
  final bool mutationInProgress;

  factory TeacherExamsListState.initial() =>
      const TeacherExamsListState(status: TeacherExamsListStatus.initial);

  TeacherExamsListState copyWith({
    TeacherExamsListStatus? status,
    String? errorMessage,
    List<dynamic>? exams,
    bool? mutationInProgress,
    bool clearError = false,
  }) {
    return TeacherExamsListState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exams: exams ?? this.exams,
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, exams, mutationInProgress];
}
