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
  Future<Either<Failure, dynamic>> getActivityDetail(String id, ActivityType type);
}