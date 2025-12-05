import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';

enum WritingTaskStatus { initial, loading, promptReady, submitting, success, error, savedSuccess }

class WritingTaskState extends Equatable {
  final WritingTaskStatus status;
  final WritingTopicEntity? topic;
  final WritingSubmissionEntity? submission;
  final String? errorMessage;

  const WritingTaskState({
    this.status = WritingTaskStatus.initial,
    this.topic,
    this.submission,
    this.errorMessage,
  });

  WritingTaskState copyWith({
    WritingTaskStatus? status,
    WritingTopicEntity? topic,
    WritingSubmissionEntity? submission,
    String? errorMessage,
  }) {
    return WritingTaskState(
      status: status ?? this.status,
      topic: topic ?? this.topic,
      submission: submission ?? this.submission,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, topic, submission, errorMessage];
}