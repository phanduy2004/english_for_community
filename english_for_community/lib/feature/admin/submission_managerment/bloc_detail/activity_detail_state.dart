import 'package:equatable/equatable.dart';
// Import đúng đường dẫn các Entity của bạn
import '../../../../../../core/entity/writing_submission_entity.dart';
import '../../../../../../core/entity/reading/reading_attempt_entity.dart';
import '../../../../../../core/entity/speaking/speaking_set_entity.dart'; // Speaking Set chứa cả sentences & history
import '../../../../../../core/entity/dictation_attempt_entity.dart';

enum DetailStatus { initial, loading, success, error }

class ActivityDetailState extends Equatable {
  final DetailStatus status;
  final String? errorMessage;

  // 4 Biến chứa dữ liệu chi tiết
  final WritingSubmissionEntity? writingData;
  final ReadingAttemptEntity? readingData;

  // Speaking: Ta cần SpeakingSetEntity để hiển thị danh sách câu,
  // trong mỗi SentenceEntity đã có sẵn list 'history' (các lần nói) nhờ bạn sửa file sentence_entity.dart
  final SpeakingSetEntity? speakingData;

  // Listening: List các lần thử (Attempts)
  final List<DictationAttemptEntity>? listeningData;

  const ActivityDetailState({
    this.status = DetailStatus.initial,
    this.errorMessage,
    this.writingData,
    this.readingData,
    this.speakingData,
    this.listeningData,
  });

  ActivityDetailState copyWith({
    DetailStatus? status,
    String? errorMessage,
    WritingSubmissionEntity? writingData,
    ReadingAttemptEntity? readingData,
    SpeakingSetEntity? speakingData,
    List<DictationAttemptEntity>? listeningData,
  }) {
    return ActivityDetailState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      writingData: writingData ?? this.writingData,
      readingData: readingData ?? this.readingData,
      speakingData: speakingData ?? this.speakingData,
      listeningData: listeningData ?? this.listeningData,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, writingData, readingData, speakingData, listeningData];
}