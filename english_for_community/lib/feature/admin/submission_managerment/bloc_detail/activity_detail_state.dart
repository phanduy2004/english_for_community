import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';
import 'package:english_for_community/core/entity/reading/reading_attempt_entity.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import 'package:english_for_community/core/entity/listening_comp_entity.dart';

enum DetailStatus { initial, loading, success, error }

class ActivityDetailState extends Equatable {
  final DetailStatus status;
  final String? errorMessage;

  final WritingSubmissionEntity? writingData;
  final ReadingAttemptEntity? readingData;
  final SpeakingSetEntity? speakingData;
  final List<DictationAttemptEntity>? listeningData;

  // 🔥 CHẮC CHẮN 2 BIẾN NÀY ĐƯỢC KHAI BÁO
  final ListeningCompAttemptResult? listeningCompData;
  final ListeningCompEntity? listeningCompDetail;

  const ActivityDetailState({
    this.status = DetailStatus.initial,
    this.errorMessage,
    this.writingData,
    this.readingData,
    this.speakingData,
    this.listeningData,
    this.listeningCompData,
    this.listeningCompDetail,
  });

  ActivityDetailState copyWith({
    DetailStatus? status,
    String? errorMessage,
    WritingSubmissionEntity? writingData,
    ReadingAttemptEntity? readingData,
    SpeakingSetEntity? speakingData,
    List<DictationAttemptEntity>? listeningData,
    ListeningCompAttemptResult? listeningCompData,
    ListeningCompEntity? listeningCompDetail,
  }) {
    return ActivityDetailState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      writingData: writingData ?? this.writingData,
      readingData: readingData ?? this.readingData,
      speakingData: speakingData ?? this.speakingData,
      listeningData: listeningData ?? this.listeningData,
      listeningCompData: listeningCompData ?? this.listeningCompData,
      listeningCompDetail: listeningCompDetail ?? this.listeningCompDetail,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    writingData,
    readingData,
    speakingData,
    listeningData,
    listeningCompData,
    listeningCompDetail,
  ];
}