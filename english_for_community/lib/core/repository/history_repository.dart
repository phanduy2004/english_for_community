// feature/history/data/repository/history_repository.dart
// 🔥 Import đúng file model
import '../../feature/admin/submission_managerment/model/activity_model.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<ActivityModel>>> getHistory({
    required DateTime start,
    required DateTime end,
    String? userId,
  });

  Future<Either<Failure, dynamic>> getActivityDetail(String id, ActivityType type, {String? subType});

  /// Lịch sử bài tập của user đang đăng nhập (có phân trang)
  Future<Either<Failure, ActivityHistoryListResult>> getMyHistory({
    required DateTime start,
    required DateTime end,
    ActivityType? skillFilter,
    int page = 1,
    int limit = 20,
    String sort = 'desc',
  });

  Future<Either<Failure, dynamic>> getMyActivityDetail(String id, ActivityType type, {String? subType});
}