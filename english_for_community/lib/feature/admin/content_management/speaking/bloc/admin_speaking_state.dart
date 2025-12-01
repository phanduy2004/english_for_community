import 'package:equatable/equatable.dart';
import '../../../../../../core/dtos/speaking_response_dto.dart';
import '../../../../../core/entity/speaking/speaking_set_entity.dart';

enum AdminSpeakingStatus { initial, loading, success, failure }

class AdminSpeakingState extends Equatable {
  final AdminSpeakingStatus status;
  final String? errorMessage;
  final List<SpeakingSetEntity> speakingSets;
  final SpeakingSetEntity? selectedSet; // Dùng cho Editor
  final PaginationEntity pagination;

  const AdminSpeakingState({
    this.status = AdminSpeakingStatus.initial,
    this.errorMessage,
    this.speakingSets = const [],
    this.selectedSet,
    this.pagination = const PaginationEntity(currentPage: 1, totalPages: 0, totalItems: 0),
  });

  bool get hasNextPage => pagination.currentPage < pagination.totalPages;

  AdminSpeakingState copyWith({
    AdminSpeakingStatus? status,
    String? errorMessage,
    List<SpeakingSetEntity>? speakingSets,
    SpeakingSetEntity? selectedSet,
    PaginationEntity? pagination,
    bool clearSelected = false,
  }) {
    return AdminSpeakingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      speakingSets: speakingSets ?? this.speakingSets,
      selectedSet: clearSelected ? null : (selectedSet ?? this.selectedSet),
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, speakingSets, selectedSet, pagination];
}