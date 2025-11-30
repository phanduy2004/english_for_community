import 'package:equatable/equatable.dart';

import '../../../core/entity/user_word_entity.dart';

enum ReviewStatus { initial, loading, success, error, complete }

class ReviewState extends Equatable {
  final ReviewStatus status;
  final List<UserWordEntity> wordsToReview;
  final int currentIndex;
  final bool isFlipped;
  final String errorMessage;

  const ReviewState({
    required this.status,
    required this.wordsToReview,
    required this.currentIndex,
    required this.isFlipped,
    required this.errorMessage,
  });

  factory ReviewState.initial() {
    return const ReviewState(
      status: ReviewStatus.initial,
      wordsToReview: [],
      currentIndex: 0,
      isFlipped: false,
      errorMessage: '',
    );
  }

  // Hàm tiện ích để lấy từ hiện tại
  UserWordEntity? get currentWord {
    if (wordsToReview.isNotEmpty && currentIndex < wordsToReview.length) {
      return wordsToReview[currentIndex];
    }
    return null;
  }

  ReviewState copyWith({
    ReviewStatus? status,
    List<UserWordEntity>? wordsToReview,
    int? currentIndex,
    bool? isFlipped,
    String? errorMessage,
  }) {
    return ReviewState(
      status: status ?? this.status,
      wordsToReview: wordsToReview ?? this.wordsToReview,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [status, wordsToReview, currentIndex, isFlipped, errorMessage];
}