import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import 'package:english_for_community/core/entity/reading/reading_entity.dart';
import 'package:english_for_community/core/repository/reading_repository.dart';
import 'package:english_for_community/feature/reading/bloc/reading_event.dart';
import 'package:english_for_community/feature/reading/bloc/reading_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _ReadingCacheEntry {
  const _ReadingCacheEntry({
    required this.readings,
    this.pagination,
  });

  final List<ReadingEntity> readings;
  final PaginationEntity? pagination;
}

class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  final ReadingRepository readingRepository;
  final Map<String, _ReadingCacheEntry> _cache = {};

  ReadingBloc({required this.readingRepository}) : super(ReadingState.initial()) {
    on<FetchReadingListEvent>(onFetchReadingListEvent);
  }

  Future<void> onFetchReadingListEvent(
    FetchReadingListEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (event.forceRefresh) {
      _cache.remove(event.difficulty);
    } else if (_cache.containsKey(event.difficulty)) {
      final cached = _cache[event.difficulty]!;
      emit(state.copyWith(
        status: ReadingStatus.success,
        readings: cached.readings,
        pagination: cached.pagination,
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: ReadingStatus.loading,
      readings: const [],
      errorMessage: null,
    ));

    final result = await readingRepository.getReadingListWithProgress(
      difficulty: event.difficulty,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (l) => emit(state.copyWith(
        status: ReadingStatus.error,
        errorMessage: l.message,
      )),
      (r) {
        _cache[event.difficulty] = _ReadingCacheEntry(
          readings: r.data,
          pagination: r.pagination,
        );
        emit(state.copyWith(
          status: ReadingStatus.success,
          readings: r.data,
          pagination: r.pagination,
        ));
      },
    );
  }
}
