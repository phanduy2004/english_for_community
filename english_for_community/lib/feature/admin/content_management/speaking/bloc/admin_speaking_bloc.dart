import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/repository/speaking_repository.dart';
import 'admin_speaking_event.dart';
import 'admin_speaking_state.dart';

class AdminSpeakingBloc extends Bloc<AdminSpeakingEvent, AdminSpeakingState> {
  final SpeakingRepository _repository;

  AdminSpeakingBloc(this._repository) : super(const AdminSpeakingState()) {
    on<GetAdminSpeakingListEvent>(_onGetList);
    on<GetSpeakingDetailEvent>(_onGetDetail);
    on<CreateSpeakingEvent>(_onCreate);
    on<UpdateSpeakingEvent>(_onUpdate);
    on<DeleteSpeakingEvent>(_onDelete);
    on<ClearSelectedSpeakingEvent>((event, emit) => emit(state.copyWith(clearSelected: true)));
  }

  Future<void> _onGetList(GetAdminSpeakingListEvent event, Emitter<AdminSpeakingState> emit) async {
    if (event.page != 1 && (!state.hasNextPage || state.status == AdminSpeakingStatus.loading)) return;
    if (event.page == 1) emit(state.copyWith(status: AdminSpeakingStatus.loading));

    final result = await _repository.getAdminSpeakingList(page: event.page, limit: event.limit);
    result.fold(
          (l) => emit(state.copyWith(status: AdminSpeakingStatus.failure, errorMessage: l.message)),
          (r) => emit(state.copyWith(
        status: AdminSpeakingStatus.success,
        speakingSets: event.page == 1 ? r.data : [...state.speakingSets, ...r.data],
        pagination: r.pagination,
      )),
    );
  }

  Future<void> _onGetDetail(GetSpeakingDetailEvent event, Emitter<AdminSpeakingState> emit) async {
    emit(state.copyWith(status: AdminSpeakingStatus.loading));
    final result = await _repository.getAdminSpeakingDetail(event.id);
    result.fold(
          (l) => emit(state.copyWith(status: AdminSpeakingStatus.failure, errorMessage: l.message)),
          (r) => emit(state.copyWith(status: AdminSpeakingStatus.success, selectedSet: r)),
    );
  }

  Future<void> _onCreate(CreateSpeakingEvent event, Emitter<AdminSpeakingState> emit) async {
    emit(state.copyWith(status: AdminSpeakingStatus.loading));
    final result = await _repository.createSpeakingSet(event.speakingSet);
    result.fold(
          (l) => emit(state.copyWith(status: AdminSpeakingStatus.failure, errorMessage: l.message)),
          (r) {
        emit(state.copyWith(status: AdminSpeakingStatus.success, clearSelected: true));
        add(const GetAdminSpeakingListEvent(page: 1));
      },
    );
  }

  Future<void> _onUpdate(UpdateSpeakingEvent event, Emitter<AdminSpeakingState> emit) async {
    emit(state.copyWith(status: AdminSpeakingStatus.loading));
    final result = await _repository.updateSpeakingSet(event.id, event.speakingSet);
    result.fold(
          (l) => emit(state.copyWith(status: AdminSpeakingStatus.failure, errorMessage: l.message)),
          (r) {
        emit(state.copyWith(status: AdminSpeakingStatus.success, clearSelected: true));
        add(const GetAdminSpeakingListEvent(page: 1));
      },
    );
  }

  Future<void> _onDelete(DeleteSpeakingEvent event, Emitter<AdminSpeakingState> emit) async {
    emit(state.copyWith(status: AdminSpeakingStatus.loading));
    final result = await _repository.deleteSpeakingSet(event.id);
    result.fold(
          (l) => emit(state.copyWith(status: AdminSpeakingStatus.failure, errorMessage: l.message)),
          (r) => add(const GetAdminSpeakingListEvent(page: 1)),
    );
  }
}