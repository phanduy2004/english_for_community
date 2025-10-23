import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';

enum WritingStatus { initial, loading, success, error }

class WritingState extends Equatable {
  final WritingStatus status;
  final String? errorMessage;
  final List<WritingTopicEntity> topics; // danh sách WritingTopic

  const WritingState({
    required this.status,
    this.errorMessage,
    this.topics = const [],
  });

  factory WritingState.initial() =>
      const WritingState(status: WritingStatus.initial);

  WritingState copyWith({
    WritingStatus? status,
    String? errorMessage,
    List<WritingTopicEntity>? topics,
  }) {
    return WritingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      topics: topics ?? this.topics,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, topics];
}
