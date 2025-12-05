import 'package:equatable/equatable.dart';
import '../../../../../core/entity/writing_topic_entity.dart';

abstract class AdminWritingEvent extends Equatable {
  const AdminWritingEvent();
  @override
  List<Object?> get props => [];
}

// 1. Lấy danh sách
class GetAdminWritingListEvent extends AdminWritingEvent {
  const GetAdminWritingListEvent();
}

// 2. Lấy chi tiết (cho trang Edit)
class GetWritingTopicDetailEvent extends AdminWritingEvent {
  final String id;
  const GetWritingTopicDetailEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// 3. Lưu (Create hoặc Update dựa vào việc topic.id có rỗng hay không)
class SaveWritingTopicEvent extends AdminWritingEvent {
  final WritingTopicEntity topic;
  const SaveWritingTopicEvent(this.topic);
  @override
  List<Object?> get props => [topic];
}

// 4. Xóa
class DeleteWritingTopicEvent extends AdminWritingEvent {
  final String id;
  const DeleteWritingTopicEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// 5. Clear state khi thoát trang Edit
class ClearSelectedWritingTopicEvent extends AdminWritingEvent {}