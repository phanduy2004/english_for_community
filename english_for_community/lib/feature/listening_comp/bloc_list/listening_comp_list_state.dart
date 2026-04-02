import 'package:equatable/equatable.dart';
import '../../../../core/entity/listening_comp_entity.dart';

// Phân biệt Enum với BLoC của trang Detail
enum CompListStatus { initial, loading, success, error }

class ListeningCompListState extends Equatable {
  final CompListStatus status;
  final List<ListeningCompEntity> listData;
  final String? errorMessage;

  // Các biến hỗ trợ phân trang (Load more)
  final bool hasReachedMax;
  final int currentPage;

  const ListeningCompListState({
    this.status = CompListStatus.initial,
    this.listData = const [],
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  ListeningCompListState copyWith({
    CompListStatus? status,
    List<ListeningCompEntity>? listData,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return ListeningCompListState(
      status: status ?? this.status,
      listData: listData ?? this.listData,
      errorMessage: errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    listData,
    errorMessage,
    hasReachedMax,
    currentPage,
  ];
}