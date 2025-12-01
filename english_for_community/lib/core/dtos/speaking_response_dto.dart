// lib/core/dtos/speaking_response_dto.dart
import 'package:equatable/equatable.dart';

// Đây là Entity cho metadata phân trang
class PaginationEntity extends Equatable {
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const PaginationEntity({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  factory PaginationEntity.fromJson(Map<String, dynamic> json) {
    return PaginationEntity(
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
    );
  }
  bool get hasNextPage => currentPage < totalPages;
  // Giá trị mặc định khi không có kết quả
  factory PaginationEntity.empty() {
    return const PaginationEntity(currentPage: 1, totalPages: 0, totalItems: 0);
  }

  @override
  List<Object?> get props => [currentPage, totalPages, totalItems];
}

// Đây là Entity cho 1 item trong danh sách SpeakingHubPage
// (Khớp với $project trong 'speaking.service.js')
class SpeakingSetProgressEntity extends Equatable {
  final String id;
  final String title;
  final int totalSentences;
  final double progress; // 0..1
  final int? bestScore;  // 0..100 (đã làm tròn)
  final bool isResumed;

  const SpeakingSetProgressEntity({
    required this.id,
    required this.title,
    required this.totalSentences,
    required this.progress,
    this.bestScore,
    required this.isResumed,
  });

  factory SpeakingSetProgressEntity.fromJson(Map<String, dynamic> json) {
    return SpeakingSetProgressEntity(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      totalSentences: (json['totalSentences'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      bestScore: (json['bestScore'] as num?)?.toInt(), // Có thể là null
      isResumed: (json['isResumed'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, totalSentences, progress, bestScore, isResumed];
}

// Helper class để bọc kết quả phân trang
class PaginatedResult<T> {
  final List<T> data;
  final PaginationEntity pagination;
  PaginatedResult({required this.data, required this.pagination});
}