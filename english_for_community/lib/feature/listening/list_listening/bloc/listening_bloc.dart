import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:english_for_community/core/repository/listening_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'listening_event.dart';
import 'listening_state.dart';

class ListeningBloc extends Bloc<ListeningEvent, ListeningState> {
  final ListeningRepository listeningRepository;
  final Map<String, List<ListeningEntity>> _listCache = {};

  ListeningBloc({required this.listeningRepository}) : super(ListeningState.initial()) {
    on<GetListeningByIdEvent>(onGetListeningByIdEvent);
    on<GetListListeningEvent>(onGetListListeningEvent);
  }

  String _cacheKey(String? difficulty) => difficulty ?? '__all__';

  Future onGetListeningByIdEvent(GetListeningByIdEvent event, Emitter<ListeningState> emit) async {
    emit(state.copyWith(status: ListeningStatus.loading));
    var result = await listeningRepository.getListeningById(event.id);
    result.fold(
      (l) => emit(state.copyWith(status: ListeningStatus.error, errorMessage: l.message)),
      (r) => emit(state.copyWith(status: ListeningStatus.success, listeningEntity: r)),
    );
  }

  Future onGetListListeningEvent(GetListListeningEvent event, Emitter<ListeningState> emit) async {
    final key = _cacheKey(event.difficulty);

    if (event.forceRefresh) {
      _listCache.remove(key);
    } else if (_listCache.containsKey(key)) {
      emit(state.copyWith(
        status: ListeningStatus.success,
        listListeningEntity: _listCache[key],
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: ListeningStatus.loading,
      listListeningEntity: const [],
      errorMessage: null,
    ));

    var result = await listeningRepository.getListenings(
      page: 1,
      limit: 100,
      difficulty: event.difficulty,
    );
    result.fold(
      (l) => emit(state.copyWith(status: ListeningStatus.error, errorMessage: l.message)),
      (r) {
        _listCache[key] = r.data;
        emit(state.copyWith(status: ListeningStatus.success, listListeningEntity: r.data));
      },
    );
  }
}
