import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repository/speaking_repository.dart';
import 'speaking_phase2_event.dart';
import 'speaking_phase2_state.dart';

class SpeakingPhase2Bloc
    extends Bloc<SpeakingPhase2Event, SpeakingPhase2State> {
  final SpeakingRepository speakingRepository;

  SpeakingPhase2Bloc({required this.speakingRepository})
      : super(SpeakingPhase2State.initial()) {
    on<LoadSpeakingScenariosEvent>(_onLoadScenarios);
    on<LoadSpeakingProgressEvent>(_onLoadProgress);
    on<LoadSpeakingNotebookEvent>(_onLoadNotebook);
  }

  Future<void> _onLoadScenarios(
    LoadSpeakingScenariosEvent event,
    Emitter<SpeakingPhase2State> emit,
  ) async {
    emit(state.copyWith(
        status: SpeakingPhase2Status.loading, errorMessage: null));
    final result =
        await speakingRepository.getSpeakingScenarios(level: event.level);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpeakingPhase2Status.error,
        errorMessage: failure.message,
      )),
      (scenarios) => emit(state.copyWith(
        status: SpeakingPhase2Status.success,
        scenarios: scenarios,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onLoadProgress(
    LoadSpeakingProgressEvent event,
    Emitter<SpeakingPhase2State> emit,
  ) async {
    emit(state.copyWith(
        status: SpeakingPhase2Status.loading, errorMessage: null));
    final result =
        await speakingRepository.getSpeakingProgressSummary(range: event.range);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpeakingPhase2Status.error,
        errorMessage: failure.message,
      )),
      (progress) => emit(state.copyWith(
        status: SpeakingPhase2Status.success,
        progress: progress,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onLoadNotebook(
    LoadSpeakingNotebookEvent event,
    Emitter<SpeakingPhase2State> emit,
  ) async {
    emit(state.copyWith(
        status: SpeakingPhase2Status.loading, errorMessage: null));
    final result =
        await speakingRepository.getSpeakingNotebook(limit: event.limit);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpeakingPhase2Status.error,
        errorMessage: failure.message,
      )),
      (notebook) => emit(state.copyWith(
        status: SpeakingPhase2Status.success,
        notebook: notebook,
        errorMessage: null,
      )),
    );
  }
}
