import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repository/speaking_repository.dart';
import 'speaking_feedback_event.dart';
import 'speaking_feedback_state.dart';

class SpeakingFeedbackBloc
    extends Bloc<SpeakingFeedbackEvent, SpeakingFeedbackState> {
  final SpeakingRepository speakingRepository;

  SpeakingFeedbackBloc({required this.speakingRepository})
      : super(SpeakingFeedbackState.initial()) {
    on<EvaluateConversationEvent>(_onEvaluateConversation);
    on<LoadConversationEvent>(_onLoadConversation);
    on<LoadConversationHistoryEvent>(_onLoadHistory);
  }

  Future<void> _onEvaluateConversation(
    EvaluateConversationEvent event,
    Emitter<SpeakingFeedbackState> emit,
  ) async {
    emit(state.copyWith(
      status: SpeakingFeedbackStatus.evaluating,
      errorMessage: null,
    ));
    final result = await speakingRepository.evaluateConversation(
      turns: event.turns,
      durationSeconds: event.durationSeconds,
      startedAt: event.startedAt,
      endedAt: event.endedAt,
      level: event.level,
      scenarioId: event.scenarioId,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpeakingFeedbackStatus.error,
        errorMessage: failure.message,
      )),
      (conversation) => emit(state.copyWith(
        status: SpeakingFeedbackStatus.reviewed,
        conversation: conversation,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onLoadConversation(
    LoadConversationEvent event,
    Emitter<SpeakingFeedbackState> emit,
  ) async {
    emit(state.copyWith(
      status: SpeakingFeedbackStatus.loading,
      errorMessage: null,
    ));
    final result = await speakingRepository.getConversationById(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpeakingFeedbackStatus.error,
        errorMessage: failure.message,
      )),
      (conversation) => emit(state.copyWith(
        status: SpeakingFeedbackStatus.reviewed,
        conversation: conversation,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onLoadHistory(
    LoadConversationHistoryEvent event,
    Emitter<SpeakingFeedbackState> emit,
  ) async {
    emit(state.copyWith(
      status: SpeakingFeedbackStatus.loading,
      errorMessage: null,
    ));
    final result = await speakingRepository.getConversationHistory(
      limit: event.limit,
      cursor: event.cursor,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpeakingFeedbackStatus.error,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: SpeakingFeedbackStatus.historyLoaded,
        history: page.data,
        errorMessage: null,
      )),
    );
  }
}
