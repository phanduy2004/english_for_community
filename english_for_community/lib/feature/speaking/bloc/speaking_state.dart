// lib/feature/speaking/bloc/speaking_state.dart
import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';

enum SpeakingStatus { initial, loading, success, error }

class SpeakingState extends Equatable {
  final SpeakingStatus status;
  final String? errorMessage;
  final List<SpeakingSetProgressEntity> sets; // Danh sách bài học
  final PaginationEntity? pagination; // Thông tin phân trang

  const SpeakingState({
    required this.status,
    this.errorMessage,
    this.sets = const [],
    this.pagination,
  });

  factory SpeakingState.initial() =>
      const SpeakingState(status: SpeakingStatus.initial);

  SpeakingState copyWith({
    SpeakingStatus? status,
    String? errorMessage,
    List<SpeakingSetProgressEntity>? sets,
    PaginationEntity? pagination,
  }) {
    return SpeakingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      sets: sets ?? this.sets,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, sets, pagination];
}