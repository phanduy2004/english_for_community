import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';

abstract class WritingTaskEvent extends Equatable {
  const WritingTaskEvent();
  @override
  List<Object> get props => [];
}

class GeneratePromptAndStartTask extends WritingTaskEvent {
  final WritingTopicEntity topic;
  final String userId;
  final String taskType;

  const GeneratePromptAndStartTask({
    required this.topic,
    required this.userId,
    required this.taskType,
  });

  @override
  List<Object> get props => [topic, userId, taskType];
}

class DiscardDraftAndStartNew extends WritingTaskEvent {
  final String oldSubmissionId;
  final WritingTopicEntity topic;
  final String userId;
  final String taskType;

  const DiscardDraftAndStartNew({
    required this.oldSubmissionId,
    required this.topic,
    required this.userId,
    required this.taskType,
  });

  @override
  List<Object> get props => [oldSubmissionId, topic, userId, taskType];
}

class SaveDraftEvent extends WritingTaskEvent {
  final String submissionId;
  final String content;

  const SaveDraftEvent({required this.submissionId, required this.content});

  @override
  List<Object> get props => [submissionId, content];
}

class SubmitForFeedback extends WritingTaskEvent {
  final String submissionId;
  final String essayContent;
  final String taskType;
  final int durationInSeconds;

  const SubmitForFeedback({
    required this.submissionId,
    required this.essayContent,
    required this.taskType,
    required this.durationInSeconds,
  });

  @override
  List<Object> get props => [submissionId, essayContent, taskType, durationInSeconds];
}