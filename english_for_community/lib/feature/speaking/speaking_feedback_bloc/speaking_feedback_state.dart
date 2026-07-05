import 'package:equatable/equatable.dart';

import '../../../core/entity/speaking_conversation_entity.dart';

enum SpeakingFeedbackStatus {
  initial,
  evaluating,
  loading,
  reviewed,
  historyLoaded,
  error,
}

class SpeakingFeedbackState extends Equatable {
  final SpeakingFeedbackStatus status;
  final SpeakingConversationEntity? conversation;
  final List<SpeakingConversationSummaryEntity> history;
  final String? errorMessage;

  const SpeakingFeedbackState({
    required this.status,
    this.conversation,
    this.history = const [],
    this.errorMessage,
  });

  factory SpeakingFeedbackState.initial() =>
      const SpeakingFeedbackState(status: SpeakingFeedbackStatus.initial);

  SpeakingFeedbackState copyWith({
    SpeakingFeedbackStatus? status,
    SpeakingConversationEntity? conversation,
    List<SpeakingConversationSummaryEntity>? history,
    String? errorMessage,
  }) {
    return SpeakingFeedbackState(
      status: status ?? this.status,
      conversation: conversation ?? this.conversation,
      history: history ?? this.history,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, conversation, history, errorMessage];
}
