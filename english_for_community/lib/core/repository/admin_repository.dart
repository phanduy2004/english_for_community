import '../entity/admin/admin_stats_entity.dart';
import '../entity/admin/paginated_response.dart';
import '../entity/report_entity.dart';
import '../entity/user_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class AdminRepository {
  Future<Either<Failure, AdminStatsEntity>> getDashboardStats({String range});

  Future<Either<Failure, PaginatedResponse<UserEntity>>> getAllUsers({
    int page,
    int limit,
    String filter,
    String? search
  });

  // Admin quản lý
  Future<Either<Failure, PaginatedResponse<ReportEntity>>> getReports({
    int page = 1,
    int limit = 20,
    String? status
  });

  Future<Either<Failure, ReportEntity>> getReportDetail(String id);

  Future<Either<Failure, ReportEntity>> updateReportStatus({
    required String id,
    required String status,
    String? adminResponse
  });

  // --- 🆕 METHODS MỚI ---
  Future<Either<Failure, UserEntity>> banUser({
    required String userId,
    required String banType,
    int? durationInHours,
    String? reason,
  });

  Future<Either<Failure, void>> deleteUser(String userId);
}