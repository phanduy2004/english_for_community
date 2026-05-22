import 'package:equatable/equatable.dart';

enum TeacherGradingHubStatus { initial, loading, success, error }

class TeacherGradingHubState extends Equatable {
  const TeacherGradingHubState({
    required this.status,
    this.errorMessage,
    this.assignment,
    this.stats = const {},
    this.attempts = const [],
    this.batchAiRunning = false,
    this.batchOpsRunning = false,
    this.attemptMutationId,
  });

  final TeacherGradingHubStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? assignment;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> attempts;
  final bool batchAiRunning;
  final bool batchOpsRunning;
  final String? attemptMutationId;

  factory TeacherGradingHubState.initial() =>
      const TeacherGradingHubState(status: TeacherGradingHubStatus.initial);

  TeacherGradingHubState copyWith({
    TeacherGradingHubStatus? status,
    String? errorMessage,
    Map<String, dynamic>? assignment,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? attempts,
    bool? batchAiRunning,
    bool? batchOpsRunning,
    String? attemptMutationId,
    bool clearAttemptMutation = false,
    bool clearError = false,
  }) {
    return TeacherGradingHubState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      assignment: assignment ?? this.assignment,
      stats: stats ?? this.stats,
      attempts: attempts ?? this.attempts,
      batchAiRunning: batchAiRunning ?? this.batchAiRunning,
      batchOpsRunning: batchOpsRunning ?? this.batchOpsRunning,
      attemptMutationId:
          clearAttemptMutation ? null : (attemptMutationId ?? this.attemptMutationId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        assignment,
        stats,
        attempts,
        batchAiRunning,
        batchOpsRunning,
        attemptMutationId,
      ];
}
