import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/user_remote_datasource.dart';
import 'package:english_for_community/core/entity/user_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource userRemoteDatasource;

  UserRepositoryImpl({required this.userRemoteDatasource});

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      return Right(await userRemoteDatasource.getProfile());
    } on DioException catch (e) {
      return Left(UserFailure(message: e.response?.data['message']));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      return Right(await userRemoteDatasource.deleteAccount());
    } on DioException catch (e) {
      return Left(UserFailure(message: e.response?.data['message']));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? goal,
    String? cefr,
    int? dailyMinutes,
    Map<String, int>? reminder,
    bool? strictCorrection,
    String? language,
    String? timezone,
  }) async {
    try {
      return Right(
        await userRemoteDatasource.updateProfile(
          fullName: fullName,
          bio: bio,
          avatarUrl: avatarUrl,
          goal: goal,
          cefr: cefr,
          dailyMinutes: dailyMinutes,
          reminder: reminder,
          strictCorrection: strictCorrection,
          language: language,
          timezone: timezone,
        ),
      );
    } on DioException catch (e) {
      return Left(UserFailure(message: e.response?.data['message']));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
}
