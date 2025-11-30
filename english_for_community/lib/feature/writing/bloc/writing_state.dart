import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart'; // Import

enum WritingStatus { initial, loading, success, error }

class WritingState extends Equatable {
  final WritingStatus status;
  final String? errorMessage;
  final List<WritingTopicEntity> topics;

  // 👇 THÊM STATE CHO HISTORY
  final WritingStatus historyStatus;
  final List<WritingSubmissionEntity> historyList;
  final String? historyErrorMessage;

  const WritingState({
    required this.status,
    this.errorMessage,
    this.topics = const [],
    // Default values
    this.historyStatus = WritingStatus.initial,
    this.historyList = const [],
    this.historyErrorMessage,
  });

  factory WritingState.initial() => const WritingState(status: WritingStatus.initial);

  WritingState copyWith({
    WritingStatus? status,
    String? errorMessage,
    List<WritingTopicEntity>? topics,
    // 👇 Params mới
    WritingStatus? historyStatus,
    List<WritingSubmissionEntity>? historyList,
    String? historyErrorMessage,
  }) {
    return WritingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      topics: topics ?? this.topics,
      // Mapping mới
      historyStatus: historyStatus ?? this.historyStatus,
      historyList: historyList ?? this.historyList,
      historyErrorMessage: historyErrorMessage ?? this.historyErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    topics,
    historyStatus,
    historyList,
    historyErrorMessage
  ];
}