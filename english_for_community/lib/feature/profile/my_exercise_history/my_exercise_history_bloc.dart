import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repository/history_repository.dart';
import '../../admin/submission_managerment/model/activity_model.dart';
import 'my_exercise_history_event.dart';
import 'my_exercise_history_state.dart';

class _HistoryCacheEntry {
  const _HistoryCacheEntry({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<ActivityModel> items;
  final int page;
  final int total;
  final bool hasMore;
}

class MyExerciseHistoryBloc extends Bloc<MyExerciseHistoryEvent, MyExerciseHistoryState> {
  final HistoryRepository _repository;
  final Map<String, _HistoryCacheEntry> _cache = {};

  MyExerciseHistoryBloc({required HistoryRepository historyRepository})
      : _repository = historyRepository,
        super(MyExerciseHistoryState.initial()) {
    on<MyExerciseHistoryFetch>(_onFetch);
    on<MyExerciseHistoryLoadMore>(_onLoadMore);
  }

  String _cacheKey(DateTimeRange range, ActivityType? skillFilter) =>
      '${range.start.millisecondsSinceEpoch}|${range.end.millisecondsSinceEpoch}|${skillFilter?.name ?? 'all'}';

  Future<void> _onFetch(MyExerciseHistoryFetch event, Emitter<MyExerciseHistoryState> emit) async {
    final key = _cacheKey(event.dateRange, event.skillFilter);

    if (event.forceRefresh) {
      _cache.remove(key);
    } else if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      emit(state.copyWith(
        status: MyExerciseHistoryStatus.success,
        errorMessage: null,
        dateRange: event.dateRange,
        skillFilter: event.skillFilter,
        setSkillFilter: true,
        page: cached.page,
        items: List.of(cached.items),
        total: cached.total,
        hasMore: cached.hasMore,
      ));
      return;
    }

    emit(state.copyWith(
      status: MyExerciseHistoryStatus.loading,
      errorMessage: null,
      dateRange: event.dateRange,
      skillFilter: event.skillFilter,
      setSkillFilter: true,
      page: 1,
      items: const [],
      hasMore: false,
    ));

    final result = await _repository.getMyHistory(
      start: event.dateRange.start,
      end: event.dateRange.end,
      skillFilter: event.skillFilter,
      page: 1,
      limit: 20,
      sort: 'desc',
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: MyExerciseHistoryStatus.error,
        errorMessage: failure.message,
      )),
      (data) {
        _cache[key] = _HistoryCacheEntry(
          items: data.items,
          page: data.page,
          total: data.total,
          hasMore: data.hasMore,
        );
        emit(state.copyWith(
          status: MyExerciseHistoryStatus.success,
          items: data.items,
          page: data.page,
          total: data.total,
          hasMore: data.hasMore,
        ));
      },
    );
  }

  Future<void> _onLoadMore(MyExerciseHistoryLoadMore event, Emitter<MyExerciseHistoryState> emit) async {
    if (!state.hasMore || state.isLoadingMore || state.status != MyExerciseHistoryStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.page + 1;
    final result = await _repository.getMyHistory(
      start: state.dateRange.start,
      end: state.dateRange.end,
      skillFilter: state.skillFilter,
      page: nextPage,
      limit: 20,
      sort: 'desc',
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        status: MyExerciseHistoryStatus.error,
        errorMessage: failure.message,
      )),
      (data) {
        final merged = [...state.items, ...data.items];
        _cache[_cacheKey(state.dateRange, state.skillFilter)] = _HistoryCacheEntry(
          items: merged,
          page: data.page,
          total: data.total,
          hasMore: data.hasMore,
        );
        emit(state.copyWith(
          isLoadingMore: false,
          status: MyExerciseHistoryStatus.success,
          items: merged,
          page: data.page,
          total: data.total,
          hasMore: data.hasMore,
        ));
      },
    );
  }
}
