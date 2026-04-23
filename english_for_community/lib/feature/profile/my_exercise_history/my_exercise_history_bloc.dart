import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repository/history_repository.dart';
import 'my_exercise_history_event.dart';
import 'my_exercise_history_state.dart';

class MyExerciseHistoryBloc extends Bloc<MyExerciseHistoryEvent, MyExerciseHistoryState> {
  final HistoryRepository _repository;

  MyExerciseHistoryBloc({required HistoryRepository historyRepository})
      : _repository = historyRepository,
        super(MyExerciseHistoryState.initial()) {
    on<MyExerciseHistoryFetch>(_onFetch);
    on<MyExerciseHistoryLoadMore>(_onLoadMore);
  }

  Future<void> _onFetch(MyExerciseHistoryFetch event, Emitter<MyExerciseHistoryState> emit) async {
    emit(state.copyWith(
      status: MyExerciseHistoryStatus.loading,
      errorMessage: null,
      dateRange: event.dateRange,
      skillFilter: event.skillFilter,
      setSkillFilter: true,
      page: 1,
      items: [],
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
      (data) => emit(state.copyWith(
        status: MyExerciseHistoryStatus.success,
        items: data.items,
        page: data.page,
        total: data.total,
        hasMore: data.hasMore,
      )),
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
