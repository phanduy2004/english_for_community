import 'dart:io';
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
  Future<Either<Failure, void>> triggerTestNotification() async {
    try {
      await userRemoteDatasource.triggerTestNotification();
      return Right(null);
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> updateFcmToken(String token) async {
    try {
      await userRemoteDatasource.updateFcmToken(token);
      return Right(null);
    } catch (e) {
      // Lỗi update token không quá nghiêm trọng, có thể chỉ log lại
      return Left(UserFailure(message: e.toString()));
    }
  }
  // Helper xử lý lỗi an toàn
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
  @override
  Future<Either<Failure, UserEntity>> getPublicProfile(String userId) async {
    try {
      return Right(await userRemoteDatasource.getPublicProfile(userId));
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
  // 🔥 IMPLEMENT HÀM ADMIN GET USER
  @override
  Future<Either<Failure, UserEntity>> getUserById(String id) async {
    try {
      return Right(await userRemoteDatasource.getUserById(id));
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      return Right(await userRemoteDatasource.getProfile());
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      return Right(await userRemoteDatasource.deleteAccount());
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    File? avatarFile, // Chỉ nhận File
    String? goal,
    String? cefr,
    int? dailyMinutes,
    Map<String, int>? reminder,
    int? dailyLessonGoal,
    bool? strictCorrection,
    String? language,
    String? timezone,
    String? gender
  }) async {
    try {
      return Right(
        await userRemoteDatasource.updateProfile(
          fullName: fullName,
          username: username,
          phone: phone,
          dateOfBirth: dateOfBirth,
          bio: bio,
          avatarFile: avatarFile, // Truyền File xuống Datasource
          goal: goal,
          cefr: cefr,
          dailyMinutes: dailyMinutes,
          reminder: reminder,
          dailyLessonGoal: dailyLessonGoal,
          strictCorrection: strictCorrection,
          language: language,
          timezone: timezone,
          gender: gender
        ),
      );
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await userRemoteDatasource.changePassword(currentPassword, newPassword);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
}