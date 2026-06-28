import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import 'package:english_for_community/core/repository/speaking_repository.dart';
import 'package:english_for_community/feature/speaking/bloc/speaking_event.dart';
import 'package:english_for_community/feature/speaking/bloc/speaking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _SpeakingCacheEntry {
  const _SpeakingCacheEntry({
    required this.sets,
    this.pagination,
  });

  final List<SpeakingSetProgressEntity> sets;
  final PaginationEntity? pagination;
}

class SpeakingBloc extends Bloc<SpeakingEvent, SpeakingState> {
  final SpeakingRepository speakingRepository;
  final Map<String, _SpeakingCacheEntry> _cache = {};

  SpeakingBloc({required this.speakingRepository}) : super(SpeakingState.initial()) {
    on<FetchSpeakingSetsEvent>(onFetchSpeakingSetsEvent);
  }

  String _cacheKey(FetchSpeakingSetsEvent event) => '${event.mode.name}:${event.level}';

  Future<void> onFetchSpeakingSetsEvent(
    FetchSpeakingSetsEvent event,
    Emitter<SpeakingState> emit,
  ) async {
    final key = _cacheKey(event);

    if (event.forceRefresh) {
      _cache.remove(key);
    } else if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      emit(state.copyWith(
        status: SpeakingStatus.success,
        sets: cached.sets,
        pagination: cached.pagination,
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: SpeakingStatus.loading,
      sets: const [],
      errorMessage: null,
    ));

    final result = await speakingRepository.getSpeakingSets(
      mode: event.mode,
      level: event.level,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (l) => emit(state.copyWith(
        status: SpeakingStatus.error,
        errorMessage: l.message,
      )),
      (r) {
        _cache[key] = _SpeakingCacheEntry(sets: r.data, pagination: r.pagination);
        emit(state.copyWith(
          status: SpeakingStatus.success,
          sets: r.data,
          pagination: r.pagination,
        ));
      },
    );
  }
}
