
import 'package:equatable/equatable.dart';

import '../../../core/entity/user_word_entity.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();
  @override
  List<Object> get props => [];
}

// Khi bắt đầu màn hình, gọi event này
class FetchReviewWords extends ReviewEvent {}

// Khi lật flashcard
class FlipCard extends ReviewEvent {}

// Khi nhấn 1 trong 3 nút (hard, good, easy)
class SubmitFeedback extends ReviewEvent {
  final String feedback;
  final UserWordEntity word;
  final int duration; // <--- Thêm trường này

  SubmitFeedback({
    required this.feedback,
    required this.word,
    required this.duration // <--- Thêm vào constructor
  });
}