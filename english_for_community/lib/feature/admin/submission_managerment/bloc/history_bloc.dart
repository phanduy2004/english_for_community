// feature/history/bloc/history_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../../../core/repository/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository historyRepository;

  HistoryBloc({required this.historyRepository}) : super(HistoryState.initial()) {
    on<FetchHistoryEvent>(_onFetchHistory);
    on<FilterHistoryEvent>(_onFilterHistory);
  }

  Future<void> _onFetchHistory(
      FetchHistoryEvent event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(status: HistoryStatus.loading));

    final result = await historyRepository.getHistory(
      start: event.startDate,
      end: event.endDate,
      userId: event.userId, // 🔥 Truyền userId xuống
    );

    result.fold(
          (failure) => emit(state.copyWith(
          status: HistoryStatus.error,
          errorMessage: failure.message
      )),
          (data) => emit(state.copyWith(
        status: HistoryStatus.success,
        allActivities: data,
        filteredActivities: data,
        dateRange: DateTimeRange(start: event.startDate, end: event.endDate),
      )),
    );
  }

  void _onFilterHistory(
      FilterHistoryEvent event, Emitter<HistoryState> emit) {
    final allData = state.allActivities;
    if (event.filterType == null) {
      emit(state.copyWith(filteredActivities: allData));
    } else {
      final filtered = allData.where((e) => e.type == event.filterType).toList();
      emit(state.copyWith(filteredActivities: filtered));
    }
  }
}