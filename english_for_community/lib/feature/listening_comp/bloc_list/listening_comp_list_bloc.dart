import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entity/listening_comp_entity.dart';
import '../../../../core/repository/listening_comp_repository.dart';
import 'listening_comp_list_event.dart';
import 'listening_comp_list_state.dart';

class _CompListCacheEntry {
  const _CompListCacheEntry({
    required this.items,
    required this.hasReachedMax,
    required this.currentPage,
  });

  final List<ListeningCompEntity> items;
  final bool hasReachedMax;
  final int currentPage;
}

class ListeningCompListBloc extends Bloc<ListeningCompListEvent, ListeningCompListState> {
  final ListeningCompRepository repository;
  final Map<String, _CompListCacheEntry> _cache = {};

  ListeningCompListBloc({required this.repository}) : super(const ListeningCompListState()) {
    on<FetchListeningCompList>(_onFetchList);
    on<LoadMoreListeningCompList>(_onLoadMore);
  }

  String _cacheKey(String? difficulty) => difficulty ?? '__all__';

  Future<void> _onFetchList(
    FetchListeningCompList event,
    Emitter<ListeningCompListState> emit,
  ) async {
    final key = _cacheKey(event.difficulty);

    if (event.forceRefresh) {
      _cache.remove(key);
    } else if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      emit(state.copyWith(
        status: CompListStatus.success,
        listData: cached.items,
        hasReachedMax: cached.hasReachedMax,
        currentPage: cached.currentPage,
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: CompListStatus.loading,
      listData: const [],
      errorMessage: null,
    ));

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
          final isMax = paginatedResult.currentPage >= paginatedResult.totalPages;

          _cache[key] = _CompListCacheEntry(
            items: items,
            hasReachedMax: isMax,
            currentPage: 2,
          );

          emit(state.copyWith(
            status: CompListStatus.success,
            listData: items,
            hasReachedMax: isMax,
            currentPage: 2,
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
          final isMax = paginatedResult.currentPage >= paginatedResult.totalPages;
          final merged = List<ListeningCompEntity>.of(state.listData)..addAll(items);

          _cache[_cacheKey(event.difficulty)] = _CompListCacheEntry(
            items: merged,
            hasReachedMax: isMax,
            currentPage: state.currentPage + 1,
          );

          emit(state.copyWith(
            status: CompListStatus.success,
            listData: merged,
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
