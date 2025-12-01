// lib/feature/reading/reading_attempt_bloc/reading_attempt_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/repository/reading_repository.dart';
import 'reading_attempt_event.dart';
import 'reading_attempt_state.dart';

class ReadingAttemptBloc extends Bloc<ReadingAttemptEvent, ReadingAttemptState> {
  final ReadingRepository readingRepository;

  ReadingAttemptBloc({required this.readingRepository})
      : super(ReadingAttemptState.initial()) {

    on<SubmitAttemptEvent>(onSubmitAttemptEvent);
    on<ResetAttemptEvent>(onResetAttemptEvent);
    on<FetchLastAttemptEvent>(onFetchLastAttemptEvent);
  }

  Future<void> onFetchLastAttemptEvent(
      FetchLastAttemptEvent event,
      Emitter<ReadingAttemptState> emit,
      ) async {
    // ... (Hàm này giữ nguyên, không thay đổi)
    emit(state.copyWith(status: AttemptStatus.loading));
    final result = await readingRepository.getAttemptHistory(event.readingId);
    result.fold(
          (l) { // Lỗi
        emit(state.copyWith(
          status: AttemptStatus.error,
          errorMessage: l.message,
        ));
      },
          (r_history) {
        if (r_history.isEmpty) {
          emit(state.copyWith(status: AttemptStatus.initial));
        } else {
          emit(state.copyWith(
            status: AttemptStatus.review,
            attemptResult: r_history.first, // Backend đã sắp xếp sẵn
          ));
        }
      },
    );
  }

  Future<void> onSubmitAttemptEvent(
      SubmitAttemptEvent event,
      Emitter<ReadingAttemptState> emit,
      ) async {
    // 1. Phát trạng thái Loading
    emit(state.copyWith(status: AttemptStatus.loading));

    // 2. Gọi Repository
    final result = await readingRepository.submitReadingAttempt(
      readingId: event.payload.readingId,
      answers: event.payload.answers,
      score: event.payload.score,
      correctCount: event.payload.correctCount,
      totalQuestions: event.payload.totalQuestions,
      durationInSeconds: event.payload.durationInSeconds, // <-- ĐÃ THÊM
    );

    // 3. Xử lý kết quả
    result.fold(
          (l) { // Lỗi
        emit(state.copyWith(
          status: AttemptStatus.error,
          errorMessage: l.message,
        ));
      },
          (r) { // Thành công (r = ReadingAttemptEntity)
        emit(state.copyWith(
          status: AttemptStatus.success,
          attemptResult: r, // 👈 Lưu kết quả
        ));
      },
    );
  }

  /// Reset BLoC về trạng thái ban đầu
  void onResetAttemptEvent(
      ResetAttemptEvent event,
      Emitter<ReadingAttemptState> emit,
      ) {
    emit(ReadingAttemptState.initial());
  }
}