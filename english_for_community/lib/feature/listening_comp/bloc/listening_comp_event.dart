import 'package:equatable/equatable.dart';

abstract class ListeningCompEvent extends Equatable {
  const ListeningCompEvent();

  @override
  List<Object?> get props => [];
}

// Gọi khi mở màn hình tải đề bài & check lịch sử
class FetchListeningCompDetail extends ListeningCompEvent {
  final String id;
  final bool isRetake; // 🔥 THÊM DÒNG NÀY

  const FetchListeningCompDetail(this.id, {this.isRetake = false}); // Mặc định là false

  @override
  List<Object?> get props => [id, isRetake];
}

// Gọi khi nộp bài
class SubmitListeningCompAttempt extends ListeningCompEvent {
  final String listeningId;
  final List<Map<String, dynamic>> answers;
  final int durationInSeconds;

  const SubmitListeningCompAttempt({
    required this.listeningId,
    required this.answers,
    required this.durationInSeconds,
  });

  @override
  List<Object?> get props => [listeningId, answers, durationInSeconds];
}

// Khởi tạo lại bài (Làm lại)
class ResetListeningCompAttempt extends ListeningCompEvent {}