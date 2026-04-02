import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repository/listening_comp_repository.dart';
import 'listening_comp_list_event.dart';
import 'listening_comp_list_state.dart';

class ListeningCompListBloc extends Bloc<ListeningCompListEvent, ListeningCompListState> {
  final ListeningCompRepository repository;

  ListeningCompListBloc({required this.repository}) : super(const ListeningCompListState()) {
    on<FetchListeningCompList>(_onFetchList);
    on<LoadMoreListeningCompList>(_onLoadMore);
  }

  Future<void> _onFetchList(
      FetchListeningCompList event,
      Emitter<ListeningCompListState> emit,
      ) async {
    // Nếu refresh (hoặc đổi filter), reset data và hiện loading
    if (event.isRefresh) {
      emit(state.copyWith(
        status: CompListStatus.loading,
        listData: [],
        currentPage: 1,
        hasReachedMax: false,
      ));
    } else if (state.status == CompListStatus.initial) {
      emit(state.copyWith(status: CompListStatus.loading));
    }

    try {
      final result = await repository.getListenings(
        difficulty: event.difficulty,
        page: 1,
        limit: 20,
      );

      result.fold(
            (failure) => emit(state.copyWith(
          status: CompListStatus.error,
          errorMessage: failure.message,
        )),
            (paginatedResult) {
              final items = paginatedResult.data;
              final isMax = paginatedResult.currentPage >= paginatedResult.totalPages; // <-- SỬA THÀNH THẾ NÀY

          emit(state.copyWith(
            status: CompListStatus.success,
            listData: items,
            hasReachedMax: isMax,
            currentPage: 2, // Chuẩn bị cho trang tiếp theo
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: CompListStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreListeningCompList event,
      Emitter<ListeningCompListState> emit,
      ) async {
    if (state.hasReachedMax || state.status == CompListStatus.loading) return;

    try {
      final result = await repository.getListenings(
        difficulty: event.difficulty,
        page: state.currentPage,
        limit: 20,
      );

      result.fold(
            (failure) => emit(state.copyWith(
          status: CompListStatus.error,
          errorMessage: failure.message,
        )),
            (paginatedResult) {
              final items = paginatedResult.data;
              final isMax = paginatedResult.currentPage >= paginatedResult.totalPages; // <-- SỬA THÀNH THẾ NÀY

          emit(state.copyWith(
            status: CompListStatus.success,
            listData: List.of(state.listData)..addAll(items),
            hasReachedMax: isMax,
            currentPage: state.currentPage + 1,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: CompListStatus.error, errorMessage: e.toString()));
    }
  }
}