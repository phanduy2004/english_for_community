import 'package:equatable/equatable.dart';

import '../../../../../core/dtos/speaking_response_dto.dart';
import '../../../../../core/entity/cue_entity.dart';
import '../../../../../core/entity/listening_entity.dart'; // Chứa PaginationEntity

enum AdminListeningStatus { initial, loading, success, failure }

class AdminListeningState extends Equatable {
  final AdminListeningStatus status;
  final String? errorMessage;

  // Dữ liệu cho List View
  final List<ListeningEntity> listenings;
  final PaginationEntity pagination;

  // Dữ liệu cho Editor View
  final ListeningEntity? selectedListening;

  const AdminListeningState({
    this.status = AdminListeningStatus.initial,
    this.errorMessage,
    this.listenings = const [],
    this.pagination = const PaginationEntity(currentPage: 1, totalPages: 0, totalItems: 0),
    this.selectedListening,
  });

  // Getter tiện ích cho UI Editor: lấy cues từ selectedListening hoặc rỗng
  List<CueEntity> get cues => selectedListening?.cues ?? [];

  // Getter kiểm tra còn trang sau không (cho Infinite Scroll)
  bool get hasNextPage => pagination.currentPage < pagination.totalPages;

  AdminListeningState copyWith({
    AdminListeningStatus? status,
    String? errorMessage,
    List<ListeningEntity>? listenings,
    PaginationEntity? pagination,
    ListeningEntity? selectedListening,
    bool clearSelected = false, // Cờ để force clear selectedListening
  }) {
    return AdminListeningState(
      status: status ?? this.status,
      errorMessage: errorMessage, // Reset lỗi mỗi lần copy trừ khi truyền vào
      listenings: listenings ?? this.listenings,
      pagination: pagination ?? this.pagination,
      selectedListening: clearSelected ? null : (selectedListening ?? this.selectedListening),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, listenings, pagination, selectedListening];
}