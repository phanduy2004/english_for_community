import 'package:equatable/equatable.dart';
import '../../../../../core/entity/cue_entity.dart';
import '../../../../../core/entity/listening_entity.dart';

abstract class AdminListeningEvent extends Equatable {
  const AdminListeningEvent();

  @override
  List<Object?> get props => [];
}

// 1. Sự kiện lấy danh sách (cho ListView)
class GetAdminListeningListEvent extends AdminListeningEvent {
  final int page;
  final int limit;
  final String difficulty;

  const GetAdminListeningListEvent({
    this.page = 1,
    this.limit = 20,
    this.difficulty = 'all',
  });

  @override
  List<Object?> get props => [page, limit, difficulty];
}

// 2. Sự kiện lấy chi tiết (cho Editor - Load data)
class GetListeningDetailEvent extends AdminListeningEvent {
  final String id;
  const GetListeningDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// 3. Sự kiện tạo mới / Cập nhật (cho Editor - Save)
class CreateListeningEvent extends AdminListeningEvent {
  final ListeningEntity listening;
  final List<CueEntity> cues; // Nhận thêm list cues rời để xử lý nếu cần

  const CreateListeningEvent({
    required this.listening,
    required this.cues,
  });

  @override
  List<Object?> get props => [listening, cues];
}
class UpdateListeningEvent extends AdminListeningEvent {
  final String id;
  final ListeningEntity listening;
  final List<CueEntity> cues;

  const UpdateListeningEvent({
    required this.id,
    required this.listening,
    required this.cues,
  });

  @override
  List<Object?> get props => [id, listening, cues];
}
class DeleteListeningEvent extends AdminListeningEvent {
  final String id;
  const DeleteListeningEvent(this.id);

  @override
  List<Object?> get props => [id];
}
// 4. Sự kiện xóa dữ liệu selected khi thoát Editor
class ClearSelectedListeningEvent extends AdminListeningEvent {}