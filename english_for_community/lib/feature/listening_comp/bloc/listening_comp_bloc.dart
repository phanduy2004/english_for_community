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
      // Khởi tạo state mới hoàn toàn để xoá sạch tàn dư (data/đáp án) của bài trước.
      emit(const ListeningCompState(status: CompStatus.loading));

      final result = await repo.getListeningById(event.id);

      await result.fold(
        (failure) async => emit(state.copyWith(
          status: CompStatus.error,
          errorMessage: failure.message,
        )),
        (entity) async {
          // Retake: đã clear sạch ở trên, chỉ gán data để làm như bài mới.
          if (event.isRetake) {
            emit(state.copyWith(
              status: CompStatus.success,
              data: entity,
              isInitialLoadReview: false,
            ));
            return;
          }

          // Kiểm tra đã từng làm bài này chưa (chế độ Start/Review bình thường).
          final attemptRes = await repo.getLatestAttempt(event.id);

          attemptRes.fold(
            (failure) =>
                emit(state.copyWith(status: CompStatus.success, data: entity)),
            (attempt) {
              if (attempt != null) {
                // Đã làm rồi -> hiện Review, không tính giờ.
                emit(state.copyWith(
                  status: CompStatus.submitted,
                  data: entity,
                  attemptResult: attempt,
                  isInitialLoadReview: true,
                ));
              } else {
                // Chưa làm -> bắt đầu tính giờ.
                emit(state.copyWith(status: CompStatus.success, data: entity));
              }
            },
          );
        },
      );
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