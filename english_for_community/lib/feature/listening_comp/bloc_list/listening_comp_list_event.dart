import 'package:equatable/equatable.dart';

abstract class ListeningCompListEvent extends Equatable {
  const ListeningCompListEvent();

  @override
  List<Object?> get props => [];
}

class FetchListeningCompList extends ListeningCompListEvent {
  final String? difficulty;
  final bool isRefresh; // Dùng khi đổi Filter hoặc Pull-to-refresh
  /// Bỏ cache và fetch lại — sau khi hoàn thành bài hoặc retry.
  final bool forceRefresh;

  const FetchListeningCompList({
    this.difficulty,
    this.isRefresh = true,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [difficulty, isRefresh, forceRefresh];
}

class LoadMoreListeningCompList extends ListeningCompListEvent {
  final String? difficulty;

  const LoadMoreListeningCompList({this.difficulty});

  @override
  List<Object?> get props => [difficulty];
}