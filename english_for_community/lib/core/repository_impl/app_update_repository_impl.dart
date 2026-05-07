import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/app_update_remote_datasource.dart';
import 'package:english_for_community/core/entity/app_update_info_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/app_update_repository.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateRemoteDatasource remoteDatasource;

  AppUpdateRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, AppUpdateInfoEntity>> checkVersion({
    required String platform,
    required int versionCode,
    String environment = 'production',
  }) async {
    try {
      final data = await remoteDatasource.checkVersion(
        platform: platform,
        versionCode: versionCode,
        environment: environment,
      );
      return Right(AppUpdateInfoEntity.fromJson(data));
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
