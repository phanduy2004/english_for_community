import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/entity/listening_comp_entity.dart';

abstract class AdminListeningCompEvent extends Equatable {
  const AdminListeningCompEvent();

  @override
  List<Object?> get props => [];
}

// Lấy danh sách bài nghe
class GetAdminListeningCompListEvent extends AdminListeningCompEvent {
  final int limit;
  final int page;
  final String? difficulty;

  const GetAdminListeningCompListEvent({required this.limit, required this.page, this.difficulty});

  @override
  List<Object?> get props => [limit, page, difficulty];
}

// Lấy chi tiết 1 bài nghe (cho Editor)
class GetListeningCompDetailEvent extends AdminListeningCompEvent {
  final String id;
  const GetListeningCompDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// Tạo bài nghe mới
class CreateListeningCompEvent extends AdminListeningCompEvent {
  final ListeningCompEntity entity;
  final PlatformFile? audioFile;

  const CreateListeningCompEvent({required this.entity, this.audioFile});

  @override
  List<Object?> get props => [entity, audioFile];
}

// Cập nhật bài nghe
class UpdateListeningCompEvent extends AdminListeningCompEvent {
  final String id;
  final ListeningCompEntity entity;
  final PlatformFile? audioFile;

  const UpdateListeningCompEvent({required this.id, required this.entity, this.audioFile});

  @override
  List<Object?> get props => [id, entity, audioFile];
}

// Xóa bài nghe
class DeleteListeningCompEvent extends AdminListeningCompEvent {
  final String id;
  const DeleteListeningCompEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// Clear state khi thoát Editor
class ClearSelectedListeningCompEvent extends AdminListeningCompEvent {}