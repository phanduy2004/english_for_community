// lib/feature/speaking/bloc/speaking_bloc.dart
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import 'package:english_for_community/core/repository/speaking_repository.dart';
import 'package:english_for_community/feature/speaking/bloc/speaking_event.dart';
import 'package:english_for_community/feature/speaking/bloc/speaking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class SpeakingBloc extends Bloc<SpeakingEvent, SpeakingState> {
  final SpeakingRepository speakingRepository;

  SpeakingBloc({required this.speakingRepository})
      : super(SpeakingState.initial()) {
    on<FetchSpeakingSetsEvent>(onFetchSpeakingSetsEvent);
  }

  Future<void> onFetchSpeakingSetsEvent(
      FetchSpeakingSetsEvent event,
      Emitter<SpeakingState> emit,
      ) async {
    // 1. Phát trạng thái Loading
    emit(state.copyWith(status: SpeakingStatus.loading));

    // 2. Gọi Repository
    final result = await speakingRepository.getSpeakingSets(
      mode: event.mode,
      level: event.level,
      page: event.page,
      limit: event.limit,
    );

    // 3. Xử lý kết quả (Fold)
    result.fold(
          (l) {
        // 4. Lỗi
        emit(state.copyWith(
          status: SpeakingStatus.error,
          errorMessage: l.message,
        ));
      },
          (r) {
        // 5. Thành công (r = PaginatedResult)
        emit(state.copyWith(
          status: SpeakingStatus.success,
          sets: r.data, // Cập nhật danh sách bài học
          pagination: r.pagination, // Cập nhật phân trang
        ));
      },
    );
  }
}