import 'package:equatable/equatable.dart';
import '../../../../../core/dtos/speaking_response_dto.dart';
import '../../../../../core/entity/reading/reading_entity.dart';

enum AdminReadingStatus {
  initial,
  loading,
  success, // Dùng cho load list / load detail
  failure,
  saved    // 👇 THÊM CÁI NÀY (Dùng riêng cho Create/Update thành công)
}
class AdminReadingState extends Equatable {
  final AdminReadingStatus status;
  final String? errorMessage;
  final List<ReadingEntity> readings;
  final PaginationEntity pagination; // 👇 Thay thế hasReachedMax bằng cái này
  final ReadingEntity? selectedReading; // 👇 Thêm biến này
  const AdminReadingState({
    this.status = AdminReadingStatus.initial,
    this.errorMessage,
    this.readings = const [],
    this.pagination = const PaginationEntity(currentPage: 1, totalPages: 0, totalItems: 0),
    this.selectedReading,
  });

  // Getter tiện lợi để UI check xem nên load tiếp không
  bool get hasNextPage => pagination.hasNextPage;

  AdminReadingState copyWith({
    AdminReadingStatus? status,
    String? errorMessage,
    List<ReadingEntity>? readings,
    PaginationEntity? pagination,
    ReadingEntity? selectedReading,
    bool clearSelectedReading = false,
  }) {
    return AdminReadingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      readings: readings ?? this.readings,
      pagination: pagination ?? this.pagination,
      selectedReading: clearSelectedReading ? null : (selectedReading ?? this.selectedReading),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, readings, pagination,selectedReading];
}