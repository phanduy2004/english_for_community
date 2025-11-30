// bloc/listening_bloc.dart
import 'package:english_for_community/core/repository/listening_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'listening_event.dart';
import 'listening_state.dart';

class ListeningBloc extends Bloc<ListeningEvent, ListeningState> {
  final ListeningRepository listeningRepository;

  ListeningBloc({required this.listeningRepository}) : super(ListeningState.initial()) {
    on<GetListeningByIdEvent>(onGetListeningByIdEvent);
    on<GetListListeningEvent>(onGetListListeningEvent);
  }

  Future onGetListeningByIdEvent(GetListeningByIdEvent event, Emitter<ListeningState> emit) async {
    emit(state.copyWith(status: ListeningStatus.loading));
    var result = await listeningRepository.getListeningById(event.id);
    result.fold(
          (l) => emit(state.copyWith(status: ListeningStatus.error, errorMessage: l.message)),
          (r) => emit(state.copyWith(status: ListeningStatus.success, listeningEntity: r)),
    );
  }

  Future onGetListListeningEvent(GetListListeningEvent event, Emitter<ListeningState> emit) async {
    emit(state.copyWith(status: ListeningStatus.loading));

    // ✅ Gọi hàm mới getListenings (có phân trang)
    var result = await listeningRepository.getListenings(page: 1, limit: 100);

    result.fold(
          (l) => emit(state.copyWith(status: ListeningStatus.error, errorMessage: l.message)),
          (r) {
        // ✅ r là PaginatedResult, ta lấy r.data để gán vào list
        emit(state.copyWith(status: ListeningStatus.success, listListeningEntity: r.data));
      },
    );
  }
}