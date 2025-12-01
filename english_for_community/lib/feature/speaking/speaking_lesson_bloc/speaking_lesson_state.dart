
import 'package:equatable/equatable.dart';

import '../../../core/entity/speaking/speaking_attempt_entity.dart';
import '../../../core/entity/speaking/speaking_set_entity.dart';

enum LessonStatus { initial, loading, submitting, success, error }

class SpeakingLessonState extends Equatable {
  final LessonStatus status;
  final SpeakingSetEntity? set; // Bài học đầy đủ (kèm sentences)
  final String? errorMessage;

  // Lưu kết quả sau khi nộp
  final SpeakingAttemptEntity? lastAttempt;

  const SpeakingLessonState({
    required this.status,
    this.set,
    this.errorMessage,
    this.lastAttempt,
  });

  factory SpeakingLessonState.initial() =>
      const SpeakingLessonState(status: LessonStatus.initial);

  SpeakingLessonState copyWith({
    LessonStatus? status,
    SpeakingSetEntity? set,
    String? errorMessage,
    SpeakingAttemptEntity? lastAttempt,
  }) {
    return SpeakingLessonState(
      status: status ?? this.status,
      set: set ?? this.set,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }

  @override
  List<Object?> get props => [status, set, errorMessage, lastAttempt];
}