import 'package:equatable/equatable.dart';
import '../../../core/entity/leaderboard_entity.dart';
import '../../../core/entity/progress_summary_entity.dart';
// ⚠️ Cần import Entity cho dữ liệu chi tiết
// Giả định bạn có file progress_detail_entity.dart
// import '../../../core/entity/progress_detail_entity.dart';

enum ProgressStatus { initial, loading, success, error }
enum LeaderboardStatus { initial, loading, success, error }
// 🔥 ENUM MỚI: Trạng thái tải dữ liệu chi tiết
enum ProgressDetailStatus { initial, loading, success, error }

class ProgressState extends Equatable {
  // --- Fields cũ (Summary) ---
  final ProgressStatus status;
  final String? errorMessage;
  final ProgressSummaryEntity? summary;

  // 🔥 FIELDS MỚI (Detail) ---
  final ProgressDetailStatus detailStatus;
  // Thay thế bằng List<ProgressDetailEntity> khi bạn có Entity đó
  final List<dynamic> detailData;
  final LeaderboardStatus leaderboardStatus;
  final List<LeaderboardUserEntity> leaderboardUsers;
  final int myRank;
  const ProgressState({
    required this.status,
    this.errorMessage,
    this.summary,
    // 🔥 KHỞI TẠO FIELDS MỚI
    required this.detailStatus,
    required this.detailData,
    required this.leaderboardStatus,
    required this.leaderboardUsers,
    required this.myRank,
  });

  // Trạng thái ban đầu
  factory ProgressState.initial() =>
      const ProgressState(
        status: ProgressStatus.initial,
        detailStatus: ProgressDetailStatus.initial, // Trạng thái Detail ban đầu
        detailData: [],
        leaderboardStatus: LeaderboardStatus.initial,
        leaderboardUsers: [],
        myRank: 0,
      );

  // Hàm copyWith để tạo state mới
  ProgressState copyWith({
    ProgressStatus? status,
    String? errorMessage,
    ProgressSummaryEntity? summary,

    // 🔥 THÊM CHO COPYWITH
    ProgressDetailStatus? detailStatus,
    List<dynamic>? detailData,
    LeaderboardStatus? leaderboardStatus,
    List<LeaderboardUserEntity>? leaderboardUsers,
    int? myRank,
  }) {
    return ProgressState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      summary: summary ?? this.summary,

      // 🔥 TRẢ VỀ FIELDS MỚI
      detailStatus: detailStatus ?? this.detailStatus,
      detailData: detailData ?? this.detailData,
      leaderboardStatus: leaderboardStatus ?? this.leaderboardStatus,
      leaderboardUsers: leaderboardUsers ?? this.leaderboardUsers,
      myRank: myRank ?? this.myRank,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    summary,
    // 🔥 THÊM CHO PROPS
    detailStatus,
    detailData,
    leaderboardStatus,
    leaderboardUsers,
    myRank,
  ];
}