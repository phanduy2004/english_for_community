import 'package:equatable/equatable.dart';
import '../../../../../core/entity/reading/reading_entity.dart';

abstract class AdminReadingEvent extends Equatable {
  const AdminReadingEvent();

  @override
  List<Object?> get props => [];
}

// Sự kiện tạo bài đọc
class CreateReadingEvent extends AdminReadingEvent {
  final ReadingEntity reading;

  const CreateReadingEvent(this.reading);

  @override
  List<Object?> get props => [reading];
}

// Sự kiện lấy danh sách (có phân trang)
class GetAdminReadingListEvent extends AdminReadingEvent {
  final int page;
  final int limit;
  final String difficulty;

  const GetAdminReadingListEvent({
    this.page = 1,
    this.limit = 10000, // Mặc định lấy số lượng lớn
    this.difficulty = 'all',
  });

  @override
  List<Object?> get props => [page, limit, difficulty];
}class GetReadingDetailEvent extends AdminReadingEvent {
  final String id;
  const GetReadingDetailEvent(this.id);
  @override
  List<Object?> get props => [id];
}
class DeleteReadingEvent extends AdminReadingEvent {
  final String id;
  const DeleteReadingEvent(this.id);

  @override
  List<Object?> get props => [id];
}
// Event để clear dữ liệu khi thoát màn hình editor (tránh hiện lại bài cũ)
class ClearSelectedReadingEvent extends AdminReadingEvent {}