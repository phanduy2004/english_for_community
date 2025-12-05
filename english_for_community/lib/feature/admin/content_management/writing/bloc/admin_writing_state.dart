import 'package:equatable/equatable.dart';
import '../../../../../core/entity/writing_topic_entity.dart';

enum AdminWritingStatus { initial, loading, success, failure, saved }

class AdminWritingState extends Equatable {
  final AdminWritingStatus status;
  final String? errorMessage;

  // Dữ liệu danh sách
  final List<WritingTopicEntity> topics;

  // Dữ liệu trang Editor
  final WritingTopicEntity? selectedTopic;

  const AdminWritingState({
    this.status = AdminWritingStatus.initial,
    this.errorMessage,
    this.topics = const [],
    this.selectedTopic,
  });

  AdminWritingState copyWith({
    AdminWritingStatus? status,
    String? errorMessage,
    List<WritingTopicEntity>? topics,
    WritingTopicEntity? selectedTopic,
    bool clearSelected = false, // Cờ để xóa selectedTopic
  }) {
    return AdminWritingState(
      status: status ?? this.status,
      errorMessage: errorMessage, // Reset lỗi nếu không truyền vào
      topics: topics ?? this.topics,
      selectedTopic: clearSelected ? null : (selectedTopic ?? this.selectedTopic),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, topics, selectedTopic];
}