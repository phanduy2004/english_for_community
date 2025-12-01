import 'package:bloc/bloc.dart';
import 'package:english_for_community/feature/vocabulary/bloc_review/review_event.dart';
import 'package:english_for_community/feature/vocabulary/bloc_review/review_state.dart';
import 'package:english_for_community/core/repository/user_vocab_repository.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final UserVocabRepository userVocabRepository;

  ReviewBloc({required this.userVocabRepository}) : super(ReviewState.initial()) {
    on<FetchReviewWords>(onFetchReviewWords);
    on<FlipCard>(onFlipCard);
    on<SubmitFeedback>(onSubmitFeedback);
  }

  Future<void> onFetchReviewWords(
      FetchReviewWords event,
      Emitter<ReviewState> emit,
      ) async {
    emit(state.copyWith(status: ReviewStatus.loading));
    final result = await userVocabRepository.getWordsToReview();
    result.fold(
          (failure) {
        emit(state.copyWith(
          status: ReviewStatus.error,
          errorMessage: failure.message,
        ));
      },
          (words) {
        if (words.isEmpty) {
          emit(state.copyWith(status: ReviewStatus.complete));
        } else {
          emit(state.copyWith(
            status: ReviewStatus.success,
            wordsToReview: words,
            currentIndex: 0,
            isFlipped: false,
          ));
        }
      },
    );
  }

  void onFlipCard(FlipCard event, Emitter<ReviewState> emit) {
    emit(state.copyWith(isFlipped: !state.isFlipped));
  }

  Future<void> onSubmitFeedback(
      SubmitFeedback event,
      Emitter<ReviewState> emit,
      ) async {
    await userVocabRepository.submitReviewFeedback(
      event.word.id!,
      event.feedback,
      event.duration, // Gửi duration xuống repository
    );

    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.wordsToReview.length) {
      emit(state.copyWith(status: ReviewStatus.complete));
    } else {
      emit(state.copyWith(
        currentIndex: nextIndex,
        isFlipped: false,
      ));
    }
  }
}