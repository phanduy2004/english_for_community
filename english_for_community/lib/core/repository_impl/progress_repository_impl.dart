// core/repository/impl/progress_repository_impl.dart
import 'package:dio/dio.dart';
import '../datasource/progress_remote_datasource.dart'; // Đường dẫn tới datasource
import '../entity/leaderboard_entity.dart';
import '../entity/progress_summary_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDatasource progressRemoteDatasource;

  ProgressRepositoryImpl({required this.progressRemoteDatasource});

  @override
  Future<Either<Failure, ProgressSummaryEntity>> getProgressSummary({
    required String range,
  }) async {
    try {
      // ✍️ SỬA LẠI: Truyền 'range' xuống datasource
      final summaryEntity = await progressRemoteDatasource.getProgressSummary(
        range: range,
      );
      return Right(summaryEntity);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi mạng không xác định';
      return Left(ProgressFailure(message: errorMessage));
    } catch (e) {
      return Left(ProgressFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, List<ProgressDetailEntity>>> getStatDetail({
    required String statKey,
    required String range,
  }) async {
    try {
      final detailList = await progressRemoteDatasource.getStatDetail(
        statKey: statKey,
        range: range,
      );
      return Right(detailList);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi mạng chi tiết không xác định';
      return Left(ProgressFailure(message: errorMessage));
    } catch (e) {
      return Left(ProgressFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, LeaderboardResultEntity>> getLeaderboard() async {
    try {
      final result = await progressRemoteDatasource.getLeaderboard();
      return Right(result);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi tải bảng xếp hạng';
      return Left(ProgressFailure(message: errorMessage));
    } catch (e) {
      return Left(ProgressFailure(message: e.toString()));
    }
  }
}