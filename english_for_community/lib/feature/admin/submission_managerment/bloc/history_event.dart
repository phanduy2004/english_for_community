// feature/history/bloc/history_event.dart

import '../model/activity_model.dart';

abstract class HistoryEvent {}

class FetchHistoryEvent extends HistoryEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? userId; // 🔥 THÊM: ID user cần xem (Null = xem của chính mình hoặc toàn bộ nếu là admin global)

  FetchHistoryEvent({
    required this.startDate,
    required this.endDate,
    this.userId,
  });
}

class FilterHistoryEvent extends HistoryEvent {
  final ActivityType? filterType; // null = All

  FilterHistoryEvent({this.filterType});
}
abstract class ActivityDetailEvent {}

class FetchActivityDetailEvent extends HistoryEvent { // (Hoặc extends ActivityDetailEvent tùy code của bạn)
  final String id;
  final ActivityType type;
  final String? subType; // 🔥 THÊM DÒNG NÀY

  FetchActivityDetailEvent({
    required this.id,
    required this.type,
    this.subType, // 🔥 THÊM DÒNG NÀY
  });

  List<Object?> get props => [id, type, subType];
}