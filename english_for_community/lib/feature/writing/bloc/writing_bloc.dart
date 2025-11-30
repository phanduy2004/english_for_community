import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/feature/writing/bloc/writing_event.dart';
import 'package:english_for_community/feature/writing/bloc/writing_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WritingBloc extends Bloc<WritingEvent, WritingState> {
  final WritingRepository writingRepository;

  WritingBloc({required this.writingRepository}) : super(WritingState.initial()) {
    on<GetWritingTopicsEvent>(_onGetWritingTopicsEvent);
    on<GetTopicHistoryEvent>(_onGetTopicHistoryEvent); // Đăng ký handler
  }

  Future<void> _onGetWritingTopicsEvent(
      GetWritingTopicsEvent event, Emitter<WritingState> emit) async {
    emit(state.copyWith(status: WritingStatus.loading));
    final result = await writingRepository.getWritingTopics();
    result.fold((l) {
      emit(state.copyWith(status: WritingStatus.error, errorMessage: l.message));
    }, (r) {
      emit(state.copyWith(status: WritingStatus.success, topics: r));
    });
  }

  // 👇 XỬ LÝ LẤY HISTORY
  Future<void> _onGetTopicHistoryEvent(
      GetTopicHistoryEvent event, Emitter<WritingState> emit) async {
    // Reset list cũ và set loading
    emit(state.copyWith(
        historyStatus: WritingStatus.loading,
        historyList: [],
        historyErrorMessage: null
    ));

    final result = await writingRepository.getTopicSubmissions(event.topicId);

    result.fold((l) {
      emit(state.copyWith(
        historyStatus: WritingStatus.error,
        historyErrorMessage: l.message,
      ));
    }, (r) {
      emit(state.copyWith(
        historyStatus: WritingStatus.success,
        historyList: r,
      ));
    });
  }
}