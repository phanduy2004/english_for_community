import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/repository/writing_repository.dart';
import 'admin_writing_event.dart';
import 'admin_writing_state.dart';

class AdminWritingBloc extends Bloc<AdminWritingEvent, AdminWritingState> {
  final WritingRepository _repository;

  AdminWritingBloc(this._repository) : super(const AdminWritingState()) {
    on<GetAdminWritingListEvent>(_onGetList);
    on<GetWritingTopicDetailEvent>(_onGetDetail);
    on<SaveWritingTopicEvent>(_onSave);
    on<DeleteWritingTopicEvent>(_onDelete);
    on<ClearSelectedWritingTopicEvent>((event, emit) => emit(state.copyWith(
      selectedTopic: null,
      status: AdminWritingStatus.initial,
      clearSelected: true,
    )));
  }

  Future<void> _onGetList(GetAdminWritingListEvent event, Emitter<AdminWritingState> emit) async {
    emit(state.copyWith(status: AdminWritingStatus.loading));
    final result = await _repository.getAdminWritingTopics();
    result.fold(
          (failure) => emit(state.copyWith(status: AdminWritingStatus.failure, errorMessage: failure.message)),
          (topics) => emit(state.copyWith(status: AdminWritingStatus.success, topics: topics)),
    );
  }

  Future<void> _onGetDetail(GetWritingTopicDetailEvent event, Emitter<AdminWritingState> emit) async {
    emit(state.copyWith(status: AdminWritingStatus.loading));
    final result = await _repository.getWritingTopicDetail(event.id);
    result.fold(
          (failure) => emit(state.copyWith(status: AdminWritingStatus.failure, errorMessage: failure.message)),
          (topic) => emit(state.copyWith(status: AdminWritingStatus.success, selectedTopic: topic)),
    );
  }

  Future<void> _onSave(SaveWritingTopicEvent event, Emitter<AdminWritingState> emit) async {
    emit(state.copyWith(status: AdminWritingStatus.loading));

    // Kiểm tra ID: Rỗng -> Create, Có ID -> Update
    final isCreate = event.topic.id.isEmpty;

    final result = isCreate
        ? await _repository.createWritingTopic(event.topic)
        : await _repository.updateWritingTopic(event.topic);

    result.fold(
          (failure) => emit(state.copyWith(status: AdminWritingStatus.failure, errorMessage: failure.message)),
          (success) {
        // Sau khi lưu thành công:
        // 1. Emit trạng thái saved để UI biết mà thoát/hiện thông báo
        // 2. Clear selected topic
        emit(state.copyWith(status: AdminWritingStatus.saved, clearSelected: true));

        // 3. Load lại danh sách (nếu đang ở trang list, tuy nhiên thường thì pop về list sẽ tự load lại nếu UI handle tốt)
        add(const GetAdminWritingListEvent());
      },
    );
  }

  Future<void> _onDelete(DeleteWritingTopicEvent event, Emitter<AdminWritingState> emit) async {
    emit(state.copyWith(status: AdminWritingStatus.loading));
    final result = await _repository.deleteWritingTopic(event.id);
    result.fold(
          (failure) => emit(state.copyWith(status: AdminWritingStatus.failure, errorMessage: failure.message)),
          (success) {
        // Xóa xong thì load lại list
        add(const GetAdminWritingListEvent());
      },
    );
  }
}