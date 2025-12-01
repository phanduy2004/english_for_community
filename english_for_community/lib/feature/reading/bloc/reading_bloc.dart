import 'package:english_for_community/core/repository/reading_repository.dart';
import 'package:english_for_community/feature/reading/bloc/reading_event.dart';
import 'package:english_for_community/feature/reading/bloc/reading_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  // ✍️ Sửa dependency thành ReadingRepository
  final ReadingRepository readingRepository;

  ReadingBloc({required this.readingRepository})
      : super(ReadingState.initial()) {
    // ✍️ Đăng ký sự kiện
    on<FetchReadingListEvent>(onFetchReadingListEvent);
  }

  Future<void> onFetchReadingListEvent(
      FetchReadingListEvent event,
      Emitter<ReadingState> emit,
      ) async {
    // 1. Phát trạng thái Loading
    emit(state.copyWith(status: ReadingStatus.loading));

    // 2. Gọi Repository của Reading
    final result = await readingRepository.getReadingListWithProgress(
      difficulty: event.difficulty, // 👈 Sửa tham số
      page: event.page,
      limit: event.limit,
    );

    // 3. Xử lý kết quả (Fold)
    result.fold(
          (l) {
        // 4. Lỗi
        emit(state.copyWith(
          status: ReadingStatus.error,
          errorMessage: l.message,
        ));
      },
          (r) {
        // 5. Thành công (r = PaginatedResult<ReadingEntity>)
        emit(state.copyWith(
          status: ReadingStatus.success,
          readings: r.data, // 👈 Cập nhật danh sách 'readings'
          pagination: r.pagination,
        ));
      },
    );
  }
}