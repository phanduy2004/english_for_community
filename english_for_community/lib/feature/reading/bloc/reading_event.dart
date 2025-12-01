import 'package:equatable/equatable.dart';

// ✍️ Class cha trừu tượng
abstract class ReadingEvent extends Equatable {
  const ReadingEvent();

  @override
  List<Object> get props => [];
}

/// Sự kiện được gọi khi trang Reading tải, hoặc khi user thay đổi filter
class FetchReadingListEvent extends ReadingEvent {
  // ✍️ Sửa lại tham số: Dùng 'difficulty' thay vì 'mode' và 'level'
  final String difficulty;
  final int page;
  final int limit;

  const FetchReadingListEvent({
    required this.difficulty,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object> get props => [difficulty, page, limit];
}