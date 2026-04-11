import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repository/listening_comp_repository.dart';

// Import 2 file Event và State đã tách biệt
import 'listening_comp_event.dart';
import 'listening_comp_state.dart';

class ListeningCompBloc extends Bloc<ListeningCompEvent, ListeningCompState> {
  final ListeningCompRepository repo;

  ListeningCompBloc({required this.repo}) : super(const ListeningCompState()) {
    // 1. Xử lý tải đề bài
    on<FetchListeningCompDetail>((event, emit) async {
      emit(state.copyWith(status: CompStatus.loading));
      final result = await repo.getListeningById(event.id);

      await result.fold(
            (failure) async => emit(state.copyWith(
          status: CompStatus.error,
          errorMessage: failure.message,
        )),
            (entity) async {
          // 🔥 THÊM LOGIC RETAKE Ở ĐÂY
          if (event.isRetake) {
            // Nếu là Retake, bỏ qua việc gọi API lấy lịch sử cũ
            emit(state.copyWith(
              status: CompStatus.success, // Trạng thái sẵn sàng tính giờ làm bài
              data: entity,
              attemptResult: null, // Đảm bảo clear sạch đáp án cũ
              isInitialLoadReview: false,
            ));
            return; // Thoát sớm, không chạy xuống đoạn getLatestAttempt bên dưới
          }

          // Kiểm tra xem đã từng làm bài này chưa (Dành cho chế độ Start / Review bình thường)
          final attemptRes = await repo.getLatestAttempt(event.id);

          attemptRes.fold(
            // Nếu lỗi lúc get lịch sử thì cứ cho làm như bài mới
                (failure) => emit(
                state.copyWith(status: CompStatus.success, data: entity)),
                (attempt) {
              if (attempt != null) {
                // Đã làm rồi -> Gán isInitialLoadReview = TRUE (Không hiện dialog)
                emit(state.copyWith(
                  status: CompStatus.submitted,
                  data: entity,
                  attemptResult: attempt,
                  isInitialLoadReview: true,
                ));
              } else {
                // Chưa làm bao giờ -> Bắt đầu tính giờ
                emit(
                    state.copyWith(status: CompStatus.success, data: entity));
              }
            },
          );
        },
      );on<FetchListeningCompDetail>((event, emit) async {

        // 🔥 CÚ CHỐT HẠ: KHÔNG DÙNG state.copyWith NỮA!
        // Khởi tạo một State mới hoàn toàn trắng tinh để xóa sạch mọi tàn dư cũ.
        emit(const ListeningCompState(status: CompStatus.loading));

        final result = await repo.getListeningById(event.id);

        await result.fold(
              (failure) async => emit(state.copyWith(
            status: CompStatus.error,
            errorMessage: failure.message,
          )),
              (entity) async {
            // 🔥 XỬ LÝ RETAKE
            if (event.isRetake) {
              // Vì ta đã clear sạch attemptResult ở trên, giờ chỉ việc gán data vào là làm bài như mới
              emit(state.copyWith(
                status: CompStatus.success,
                data: entity,
                isInitialLoadReview: false,
              ));
              return; // Thoát, không chạy xuống check lịch sử nữa
            }

            // Kiểm tra xem đã từng làm bài này chưa (Dành cho chế độ Review/Start bình thường)
            final attemptRes = await repo.getLatestAttempt(event.id);

            attemptRes.fold(
                  (failure) => emit(
                  state.copyWith(status: CompStatus.success, data: entity)),
                  (attempt) {
                if (attempt != null) {
                  // Đã làm rồi -> Hiện Review
                  emit(state.copyWith(
                    status: CompStatus.submitted,
                    data: entity,
                    attemptResult: attempt,
                    isInitialLoadReview: true,
                  ));
                } else {
                  // Chưa làm bao giờ -> Start tính giờ
                  emit(
                      state.copyWith(status: CompStatus.success, data: entity));
                }
              },
            );
          },
        );
      });
    });

    // 2. Xử lý nộp bài
    on<SubmitListeningCompAttempt>((event, emit) async {
      emit(state.copyWith(status: CompStatus.submitting));

      final result = await repo.submitAttempt(
        listeningId: event.listeningId,
        answers: event.answers,
        durationInSeconds: event.durationInSeconds,
      );

      result.fold(
            (failure) => emit(state.copyWith(
          status: CompStatus.error,
          errorMessage: failure.message,
        )),
            (successAttempt) => emit(state.copyWith(
          status: CompStatus.submitted,
          attemptResult: successAttempt,
          isInitialLoadReview: false, // Vừa nộp xong -> FALSE (Sẽ hiện dialog kết quả)
        )),
      );
    });

    // 3. Xử lý làm lại (Hàm này hiện tại có thể không dùng tới nữa vì mình đã handle bằng isRetake khi init, nhưng cứ giữ lại phòng hờ)
    on<ResetListeningCompAttempt>((event, emit) {
      emit(state.copyWith(
        status: CompStatus.success,
        attemptResult: null,
        isInitialLoadReview: false,
      ));
    });
  }
}