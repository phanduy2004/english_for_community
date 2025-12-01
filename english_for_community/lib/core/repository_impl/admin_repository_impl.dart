import 'package:dio/dio.dart';
import '../datasource/admin_remote_datasource.dart';
import '../entity/admin/admin_stats_entity.dart';
import '../entity/admin/paginated_response.dart';
import '../entity/report_entity.dart';
import '../entity/user_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDatasource adminRemoteDatasource;

  AdminRepositoryImpl({required this.adminRemoteDatasource});

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return "Kết nối quá hạn. Vui lòng kiểm tra mạng.";
    }
    if (e.response != null && e.response!.data is Map && (e.response!.data as Map).containsKey('message')) {
      return e.response!.data['message'].toString();
    }
    return e.message ?? "Lỗi không xác định";
  }

  // ... (Các hàm cũ getDashboardStats, getAllUsers, getReports, updateReportStatus GIỮ NGUYÊN) ...

  @override
  Future<Either<Failure, AdminStatsEntity>> getDashboardStats({String range = 'week'}) async {
    try {
      final result = await adminRemoteDatasource.getDashboardStats(range: range);
      return Right(result);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<UserEntity>>> getAllUsers({
    int page = 1,
    int limit = 20,
    String filter = 'all',
    String? search
  }) async {
    try {
      final result = await adminRemoteDatasource.getAllUsers(
          page: page, limit: limit, filter: filter, search: search
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<ReportEntity>>> getReports({int page = 1, int limit = 20, String? status}) async {
    try {
      final result = await adminRemoteDatasource.getReports(page: page, limit: limit, status: status);
      return Right(result);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReportEntity>> updateReportStatus({
    required String reportId,
    required String status,
    String? adminResponse
  }) async {
    try {
      final result = await adminRemoteDatasource.updateReportStatus(
        reportId: reportId, status: status, adminResponse: adminResponse,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  // --- 🆕 IMPLEMENT BAN USER ---
  @override
  Future<Either<Failure, UserEntity>> banUser({
    required String userId,
    required String banType,
    int? durationInHours,
    String? reason
  }) async {
    try {
      final result = await adminRemoteDatasource.banUser(
          userId: userId, banType: banType, durationInHours: durationInHours, reason: reason
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  // --- 🆕 IMPLEMENT DELETE USER ---
  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await adminRemoteDatasource.deleteUser(userId);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
}