// core/repository/progress_repository.dart
import '../entity/leaderboard_entity.dart';
import '../entity/progress_summary_entity.dart'; // Đường dẫn tới entity
import '../model/either.dart';
import '../model/failure.dart';


abstract class ProgressRepository {
  // Chỉ có một phương thức duy nhất là lấy tóm tắt tiến độ
  Future<Either<Failure, ProgressSummaryEntity>> getProgressSummary({
    required String range,
  });
  Future<Either<Failure, List<ProgressDetailEntity>>> getStatDetail({
    required String statKey,
    required String range,
  });
  Future<Either<Failure, LeaderboardResultEntity>> getLeaderboard();
}