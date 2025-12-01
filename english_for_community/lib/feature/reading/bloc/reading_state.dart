import 'package:equatable/equatable.dart';
// ✍️ Import DTO chung
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
// ✍️ Import entity của Reading
import 'package:english_for_community/core/entity/reading/reading_entity.dart';

// ✍️ Enum trạng thái (giống Speaking)
enum ReadingStatus { initial, loading, success, error }

class ReadingState extends Equatable {
  final ReadingStatus status;
  final String? errorMessage;
  // ✍️ Dữ liệu trả về là List<ReadingEntity>
  final List<ReadingEntity> readings;
  final PaginationEntity? pagination; // Dùng chung DTO

  const ReadingState({
    required this.status,
    this.errorMessage,
    this.readings = const [], // ✍️ Đổi tên
    this.pagination,
  });

  factory ReadingState.initial() =>
      const ReadingState(status: ReadingStatus.initial);

  ReadingState copyWith({
    ReadingStatus? status,
    String? errorMessage,
    List<ReadingEntity>? readings, // ✍️ Sửa kiểu
    PaginationEntity? pagination,
  }) {
    return ReadingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      readings: readings ?? this.readings, // ✍️ Sửa tên
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, readings, pagination];
}