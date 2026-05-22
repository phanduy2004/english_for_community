import 'package:equatable/equatable.dart';

enum TeacherApplyStatus { initial, loading, success, error, submitted }

class TeacherApplyState extends Equatable {
  const TeacherApplyState({
    required this.status,
    this.errorMessage,
    this.existingApplication,
    this.submitting = false,
  });

  final TeacherApplyStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? existingApplication;
  final bool submitting;

  factory TeacherApplyState.initial() =>
      const TeacherApplyState(status: TeacherApplyStatus.initial);

  TeacherApplyState copyWith({
    TeacherApplyStatus? status,
    String? errorMessage,
    Map<String, dynamic>? existingApplication,
    bool? submitting,
    bool clearError = false,
  }) {
    return TeacherApplyState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      existingApplication: existingApplication ?? this.existingApplication,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, existingApplication, submitting];
}
