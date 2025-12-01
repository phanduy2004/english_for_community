
import 'package:equatable/equatable.dart';

import '../../../core/entity/speaking/speaking_attempt_entity.dart';

abstract class SpeakingLessonEvent extends Equatable {
  const SpeakingLessonEvent();
  @override
  List<Object> get props => [];
}

// Event để tải chi tiết bài học
class FetchLessonDetailsEvent extends SpeakingLessonEvent {
  final String setId;
  const FetchLessonDetailsEvent({required this.setId});
  @override
  List<Object> get props => [setId];
}

// Event để nộp bài
class SubmitLessonAttemptEvent extends SpeakingLessonEvent {
  final String speakingSetId;
  final String sentenceId;
  final String userTranscript;
  final String userAudioUrl;
  final SpeakingScoreEntity score;
  final int audioDurationSeconds; // <-- THÊM DÒNG NÀY
  const SubmitLessonAttemptEvent({
    required this.speakingSetId,
    required this.sentenceId,
    required this.userTranscript,
    required this.userAudioUrl,
    required this.score,
    required this.audioDurationSeconds,
  });
}