import 'package:equatable/equatable.dart';

enum TeacherExamAttemptGradeStatus { initial, loading, success, error }

class TeacherExamAttemptGradeState extends Equatable {
  const TeacherExamAttemptGradeState({
    required this.status,
    this.errorMessage,
    this.attempt,
    this.aiGrading = false,
    this.expandedSkillSections = const {},
    this.successMessage,
  });

  final TeacherExamAttemptGradeStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? attempt;
  final bool aiGrading;
  final Set<String> expandedSkillSections;
  final String? successMessage;

  factory TeacherExamAttemptGradeState.initial() =>
      const TeacherExamAttemptGradeState(status: TeacherExamAttemptGradeStatus.initial);

  TeacherExamAttemptGradeState copyWith({
    TeacherExamAttemptGradeStatus? status,
    String? errorMessage,
    Map<String, dynamic>? attempt,
    bool? aiGrading,
    Set<String>? expandedSkillSections,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TeacherExamAttemptGradeState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      attempt: attempt ?? this.attempt,
      aiGrading: aiGrading ?? this.aiGrading,
      expandedSkillSections: expandedSkillSections ?? this.expandedSkillSections,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        attempt,
        aiGrading,
        expandedSkillSections,
        successMessage,
      ];
}
