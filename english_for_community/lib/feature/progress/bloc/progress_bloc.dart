// feature/progress/bloc/progress_bloc.dart
import 'package:english_for_community/feature/progress/bloc/progress_event.dart';
import 'package:english_for_community/feature/progress/bloc/progress_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entity/progress_summary_entity.dart';
// ⚠️ Cần import entity mới
// import '../../../core/entity/progress_detail_entity.dart';
import '../../../core/model/failure.dart';
import '../../../core/repository/progress_repository.dart';


class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressRepository progressRepository;

  ProgressBloc({required this.progressRepository})
      : super(ProgressState.initial()) {

    // Đăng ký sự kiện cũ: Tải tóm tắt tiến độ (Summary)
    on<FetchProgressData>(onFetchProgressData);
    on<FetchLeaderboard>(onFetchLeaderboard);
    // 🔥 Đăng ký sự kiện mới: Tải chi tiết thống kê (Detail)
    on<FetchStatDetail>(onFetchStatDetail);
  }
  Future<void> onFetchLeaderboard(
      FetchLeaderboard event,
      Emitter<ProgressState> emit,
      ) async {
    emit(state.copyWith(leaderboardStatus: LeaderboardStatus.loading));

    final result = await progressRepository.getLeaderboard();

    result.fold(
          (failure) {
        emit(state.copyWith(
          leaderboardStatus: LeaderboardStatus.error,
          errorMessage: failure.message,
        ));
      },
          (data) {
        emit(state.copyWith(
          leaderboardStatus: LeaderboardStatus.success,
          leaderboardUsers: data.leaderboard,
          myRank: data.myRank,
        ));
      },
    );
  }
  /// Xử lý sự kiện tải Tóm tắt Tiến độ (Summary)
  Future<void> onFetchProgressData(
      FetchProgressData event,
      Emitter<ProgressState> emit,
      ) async {
    emit(state.copyWith(status: ProgressStatus.loading));

    final result = await progressRepository.getProgressSummary(
      range: event.range,
    );

    result.fold(
          (failure) {
        emit(state.copyWith(
          status: ProgressStatus.error,
          errorMessage: failure.message,
        ));
      },
          (summary) {
        emit(state.copyWith(
          status: ProgressStatus.success,
          summary: summary,
        ));
      },
    );
  }

  // 🔥 HÀM XỬ LÝ MỚI: Tải chi tiết thống kê (Detail)
  Future<void> onFetchStatDetail(
      FetchStatDetail event,
      Emitter<ProgressState> emit,
      ) async {
    // 1. Bắt đầu tải, cập nhật trạng thái chi tiết
    emit(state.copyWith(detailStatus: ProgressDetailStatus.loading));

    // 2. Gọi Repository để lấy dữ liệu chi tiết
    final result = await progressRepository.getStatDetail(
      statKey: event.statKey,
      range: event.range,
    );

    // 3. Xử lý kết quả
    result.fold(
          (failure) {
        // Xử lý lỗi
        emit(state.copyWith(
          detailStatus: ProgressDetailStatus.error,
          errorMessage: failure.message, // Có thể dùng errorMessage chung
          detailData: const [], // Xóa dữ liệu cũ
        ));
      },
          (detailList) {
        // Tải thành công
        emit(state.copyWith(
          detailStatus: ProgressDetailStatus.success,
          detailData: detailList,
          // Đảm bảo errorMessage bị xóa nếu trước đó có lỗi
          errorMessage: null,
        ));
      },
    );
  }
}