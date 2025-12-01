import 'package:english_for_community/feature/reading/reading_attempt_bloc/reading_attempt_payload.dart';
import 'package:equatable/equatable.dart';

abstract class ReadingAttemptEvent extends Equatable {
  const ReadingAttemptEvent();
  @override
  List<Object> get props => [];
}

/// Sự kiện được gọi khi người dùng nhấn nút "Nộp bài"
class SubmitAttemptEvent extends ReadingAttemptEvent {
  final ReadingAttemptPayload payload; // 👈 Giờ đã hợp lệ

  const SubmitAttemptEvent({required this.payload});

  @override
  List<Object> get props => [payload];
}

/// Sự kiện được gọi khi người dùng nhấn "Làm lại" từ dialog
class ResetAttemptEvent extends ReadingAttemptEvent {}
/// Sự kiện được gọi khi vào trang ở chế độ "Review"
class FetchLastAttemptEvent extends ReadingAttemptEvent {
  final String readingId;

  const FetchLastAttemptEvent({required this.readingId});

  @override
  List<Object> get props => [readingId];
}
