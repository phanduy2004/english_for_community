import 'package:equatable/equatable.dart';

import '../../../core/entity/speaking_conversation_entity.dart';

abstract class SpeakingFeedbackEvent extends Equatable {
  const SpeakingFeedbackEvent();

  @override
  List<Object?> get props => [];
}

class EvaluateConversationEvent extends SpeakingFeedbackEvent {
  final List<SpeakingTurnEntity> turns;
  final int durationSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? level;
  final String? scenarioId;

  const EvaluateConversationEvent({
    required this.turns,
    required this.durationSeconds,
    this.startedAt,
    this.endedAt,
    this.level,
    this.scenarioId,
  });

  @override
  List<Object?> get props =>
      [turns, durationSeconds, startedAt, endedAt, level, scenarioId];
}

class LoadConversationEvent extends SpeakingFeedbackEvent {
  final String id;

  const LoadConversationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadConversationHistoryEvent extends SpeakingFeedbackEvent {
  final int limit;
  final String? cursor;

  const LoadConversationHistoryEvent({this.limit = 20, this.cursor});

  @override
  List<Object?> get props => [limit, cursor];
}
