import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/app_release_admin_remote_datasource.dart';
import 'package:english_for_community/core/entity/admin/app_release_admin_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/app_release_repository.dart';

class AppReleaseRepositoryImpl implements AppReleaseRepository {
  final AppReleaseAdminRemoteDatasource datasource;

  AppReleaseRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, List<AppReleaseAdminEntity>>> getReleases({
    String? status,
    String? platform,
    String? environment,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final rows = await datasource.getAppReleases(
        status: status,
        platform: platform,
        environment: environment,
        page: page,
        limit: limit,
      );
      final data = rows.map(AppReleaseAdminEntity.fromJson).toList();
      return Right(data);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ??
              e.message ??
              'Network error'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> runAction({
    required String action,
    required String releaseId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await datasource.runAction(
          action: action, releaseId: releaseId, payload: payload);
      return Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
          message: e.response?.data?['message']?.toString() ??
              e.message ??
              'Network error'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
