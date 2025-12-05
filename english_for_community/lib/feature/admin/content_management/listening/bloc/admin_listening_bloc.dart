// lib/feature/admin/content_management/listening/bloc/admin_listening_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/repository/listening_repository.dart';
import 'admin_listening_event.dart';
import 'admin_listening_state.dart';

class AdminListeningBloc extends Bloc<AdminListeningEvent, AdminListeningState> {
  final ListeningRepository _repository;

  AdminListeningBloc(this._repository) : super(const AdminListeningState()) {
    on<GetAdminListeningListEvent>(_onGetList);
    on<GetListeningDetailEvent>(_onGetDetail);
    on<CreateListeningEvent>(_onCreate);
    on<UpdateListeningEvent>(_onUpdate);
    on<ClearSelectedListeningEvent>((event, emit) => emit(state.copyWith(
      selectedListening: null,
      status: AdminListeningStatus.success,
    )));
    on<DeleteListeningEvent>(_onDelete);
  }

  // ... (Delete, GetList, GetDetail GIỮ NGUYÊN) ...

  Future<void> _onDelete(DeleteListeningEvent event, Emitter<AdminListeningState> emit) async {
    emit(state.copyWith(status: AdminListeningStatus.loading));
    final result = await _repository.deleteListening(event.id);
    result.fold(
          (failure) => emit(state.copyWith(status: AdminListeningStatus.failure, errorMessage: failure.message)),
          (success) => add(const GetAdminListeningListEvent(page: 1, limit: 9999)),
    );
  }

  Future<void> _onGetList(GetAdminListeningListEvent event, Emitter<AdminListeningState> emit) async {
    if (event.page != 1 && (!state.hasNextPage || state.status == AdminListeningStatus.loading)) return;
    if (event.page == 1) emit(state.copyWith(status: AdminListeningStatus.loading));

    final result = await _repository.getListenings(page: event.page, limit: event.limit);

    result.fold(
          (failure) => emit(state.copyWith(status: AdminListeningStatus.failure, errorMessage: failure.message)),
          (paginatedResult) {
        final newItems = event.page == 1 ? paginatedResult.data : [...state.listenings, ...paginatedResult.data];
        emit(state.copyWith(
          status: AdminListeningStatus.success,
          listenings: newItems,
          pagination: paginatedResult.pagination,
        ));
      },
    );
  }

  Future<void> _onGetDetail(GetListeningDetailEvent event, Emitter<AdminListeningState> emit) async {
    emit(state.copyWith(status: AdminListeningStatus.loading));
    final result = await _repository.getListeningById(event.id);
    result.fold(
          (failure) => emit(state.copyWith(status: AdminListeningStatus.failure, errorMessage: failure.message)),
          (listening) => emit(state.copyWith(status: AdminListeningStatus.success, selectedListening: listening)),
    );
  }

  // 🔥 SỬA LOGIC CREATE
  Future<void> _onCreate(CreateListeningEvent event, Emitter<AdminListeningState> emit) async {
    emit(state.copyWith(status: AdminListeningStatus.loading));

    // Copy cues vào listening entity cho đầy đủ
    final payload = event.listening.copyWith(cues: event.cues);

    final result = await _repository.createListening(
        payload,
        audioFile: event.audioFile // 🔥 Truyền file
    );

    result.fold(
          (failure) => emit(state.copyWith(status: AdminListeningStatus.failure, errorMessage: failure.message)),
          (successData) => emit(state.copyWith(status: AdminListeningStatus.success, clearSelected: true)),
    );
  }

  // 🔥 SỬA LOGIC UPDATE
  Future<void> _onUpdate(UpdateListeningEvent event, Emitter<AdminListeningState> emit) async {
    emit(state.copyWith(status: AdminListeningStatus.loading));

    final payload = event.listening.copyWith(cues: event.cues);

    final result = await _repository.updateListening(
        event.id,
        payload,
        audioFile: event.audioFile // 🔥 Truyền file
    );

    result.fold(
          (failure) => emit(state.copyWith(status: AdminListeningStatus.failure, errorMessage: failure.message)),
          (successData) => emit(state.copyWith(status: AdminListeningStatus.success, selectedListening: null)),
    );
  }
}