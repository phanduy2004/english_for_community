import 'package:english_for_community/core/repository/speaking_repository.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_event.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpeakingLessonBloc
    extends Bloc<SpeakingLessonEvent, SpeakingLessonState> {
  final SpeakingRepository speakingRepository;

  SpeakingLessonBloc({required this.speakingRepository})
      : super(SpeakingLessonState.initial()) {
    on<FetchLessonDetailsEvent>(onFetchLessonDetails);
    on<SubmitLessonAttemptEvent>(onSubmitLessonAttempt);
  }

  Future<void> onFetchLessonDetails(
      FetchLessonDetailsEvent event,
      Emitter<SpeakingLessonState> emit,
      ) async {

    // 🔥 CÚ CHỐT: Đưa BLoC về trạng thái nguyên thủy trắng tinh trước khi tải
    emit(SpeakingLessonState.initial().copyWith(status: LessonStatus.loading));

    final result = await speakingRepository.getSpeakingSetDetails(event.setId);
    result.fold(
          (l) => emit(state.copyWith(
        status: LessonStatus.error,
        errorMessage: l.message,
      )),
          (r) {
        // Tải xong, quăng data ra cho UI xử lý tiếp
        emit(state.copyWith(
          status: LessonStatus.success,
          set: r,
        ));
      },
    );
  }

  Future<void> onSubmitLessonAttempt(
      SubmitLessonAttemptEvent event,
      Emitter<SpeakingLessonState> emit,
      ) async {
    emit(state.copyWith(status: LessonStatus.submitting));
    final result = await speakingRepository.submitSpeakingAttempt(
      speakingSetId: event.speakingSetId,
      sentenceId: event.sentenceId,
      userTranscript: event.userTranscript,
      userAudioUrl: event.userAudioUrl,
      score: event.score,
      audioDurationSeconds: event.audioDurationSeconds,
    );
    result.fold(
          (l) => emit(state.copyWith(
        status: LessonStatus.error,
        errorMessage: l.message,
      )),
          (r) {
        emit(state.copyWith(
          status: LessonStatus.success,
          lastAttempt: r,
        ));
      },
    );
  }
}