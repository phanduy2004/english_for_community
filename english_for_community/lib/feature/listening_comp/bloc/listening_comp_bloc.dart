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
          // Kiểm tra xem đã từng làm bài này chưa
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

    // 3. Xử lý làm lại
    on<ResetListeningCompAttempt>((event, emit) {
      emit(state.copyWith(
        status: CompStatus.success,
        attemptResult: null,
        isInitialLoadReview: false,
      ));
    });
  }
}