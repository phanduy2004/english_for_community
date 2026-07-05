import 'package:equatable/equatable.dart';

import '../../../core/entity/speaking_phase2_entity.dart';

enum SpeakingPhase2Status { initial, loading, success, error }

class SpeakingPhase2State extends Equatable {
  final SpeakingPhase2Status status;
  final List<SpeakingScenarioEntity> scenarios;
  final SpeakingProgressSummaryEntity? progress;
  final SpeakingNotebookEntity? notebook;
  final String? errorMessage;

  const SpeakingPhase2State({
    required this.status,
    this.scenarios = const [],
    this.progress,
    this.notebook,
    this.errorMessage,
  });

  factory SpeakingPhase2State.initial() =>
      const SpeakingPhase2State(status: SpeakingPhase2Status.initial);

  SpeakingPhase2State copyWith({
    SpeakingPhase2Status? status,
    List<SpeakingScenarioEntity>? scenarios,
    SpeakingProgressSummaryEntity? progress,
    SpeakingNotebookEntity? notebook,
    String? errorMessage,
  }) {
    return SpeakingPhase2State(
      status: status ?? this.status,
      scenarios: scenarios ?? this.scenarios,
      progress: progress ?? this.progress,
      notebook: notebook ?? this.notebook,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, scenarios, progress, notebook, errorMessage];
}
