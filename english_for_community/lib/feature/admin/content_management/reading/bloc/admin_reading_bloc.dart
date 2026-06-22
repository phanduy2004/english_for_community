import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/repository/reading_repository.dart';
import '../../../layout/admin_widgets.dart';
import 'admin_reading_event.dart';
import 'admin_reading_state.dart';

class AdminReadingBloc extends Bloc<AdminReadingEvent, AdminReadingState> {
  final ReadingRepository _repository;

  AdminReadingBloc(this._repository) : super(const AdminReadingState()) {
    on<CreateReadingEvent>(_onCreateReading);
    on<GetAdminReadingListEvent>(_onGetList);
    on<GetReadingDetailEvent>(_onGetDetail);
    on<DeleteReadingEvent>(_onDeleteReading);
    on<ClearSelectedReadingEvent>((event, emit) => emit(state.copyWith(clearSelectedReading: true)));
  }
  Future<void> _onDeleteReading(
      DeleteReadingEvent event,
      Emitter<AdminReadingState> emit,
      ) async {
    // 1. Bật trạng thái loading (để hiện vòng xoay hoặc disable nút)
    emit(state.copyWith(status: AdminReadingStatus.loading));

    // 2. Gọi Repo xóa
    final result = await _repository.deleteReading(event.id);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AdminReadingStatus.failure,
        errorMessage: failure.message,
      )),
          (success) {
        // 3. Xóa thành công -> Gọi lại event GetList để refresh danh sách
        // Lưu ý: Không cần emit success ở đây vì GetList sẽ tự emit success khi load xong
        add(GetAdminReadingListEvent(page: 1, limit: kAdminDefaultRowsPerPage));
      },
    );
  }
  Future<void> _onGetDetail(
      GetReadingDetailEvent event,
      Emitter<AdminReadingState> emit,
      ) async {
    emit(state.copyWith(status: AdminReadingStatus.loading));

    final result = await _repository.getReadingDetail(event.id);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AdminReadingStatus.failure,
        errorMessage: failure.message,
      )),
          (reading) => emit(state.copyWith(
        status: AdminReadingStatus.success,
        selectedReading: reading, // 👇 Lưu vào state để UI hứng
      )),
    );
  }
  Future<void> _onCreateReading(
      CreateReadingEvent event,
      Emitter<AdminReadingState> emit,
      ) async {
    emit(state.copyWith(status: AdminReadingStatus.loading));

    final result = await _repository.createReading(event.reading);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AdminReadingStatus.failure,
        errorMessage: failure.message,
      )),
          (successData) => emit(state.copyWith(
        status: AdminReadingStatus.saved, // 👈 SỬA THÀNH saved
        // selectedReading: null, // Clear nếu cần
      )),
    );
  }

  Future<void> _onGetList(
      GetAdminReadingListEvent event,
      Emitter<AdminReadingState> emit,
      ) async {
    // Nếu đang loading hoặc đã hết trang (khi load more), thì bỏ qua
    // (Chỉ áp dụng logic này nếu không phải load trang 1)
    if (event.page != 1 && !state.hasNextPage) return;

    if (event.page == 1) {
      emit(state.copyWith(status: AdminReadingStatus.loading));
    }

    // Repository cần trả về Either<Failure, PaginatedResult<ReadingEntity>>
    final result = await _repository.getReadingListWithProgress(
      difficulty: event.difficulty,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
          (failure) => emit(state.copyWith(
        status: AdminReadingStatus.failure,
        errorMessage: failure.message,
      )),
          (paginatedResult) {
        // Logic nối list: Trang 1 thì thay thế, trang sau thì nối đuôi
            final newReadings = event.page == 1
                ? paginatedResult.data
                : [...state.readings, ...paginatedResult.data];
        emit(state.copyWith(
          status: AdminReadingStatus.success,
          readings: newReadings,
          pagination: paginatedResult.pagination, // Cập nhật metadata phân trang mới
        ));
      },
    );
  }
}