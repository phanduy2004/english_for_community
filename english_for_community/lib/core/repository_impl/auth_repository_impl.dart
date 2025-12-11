import 'package:dio/dio.dart';
import 'package:http/http.dart' as apiClient;

import '../datasource/auth_remote_datasource.dart';
import '../entity/auth_entity.dart';
import '../entity/user_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/auth_repository.dart';


class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource authRemoteDatasource;

  AuthRepositoryImpl({required this.authRemoteDatasource});

  // Helper xử lý lỗi chuẩn cho Auth
  String _handleDioError(DioException e) {
    // 1. Lỗi kết nối
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.";
    }

    // 2. Lỗi từ Backend trả về (400, 401, 403...)
    if (e.response != null && e.response!.data is Map) {
      final data = e.response!.data as Map;
      // Backend trả về: { "message": "Tài khoản bị khóa...", "reason": "..." }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }

    // 3. Lỗi mặc định
    return e.message ?? "Lỗi xác thực không xác định";
  }
  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle(String idToken) async {
    try {
      final user = await authRemoteDatasource.loginWithGoogle(idToken);
      return Right(user);
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final result = await authRemoteDatasource.login(email, password);
      return Right(result);
    } on DioException catch (e) {
      // Bắt lỗi Dio và format lại message
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    try {
      await authRemoteDatasource.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
      );
      return Right(null);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  // 🔥 MỚI: Triển khai Gửi lại OTP
  @override
  Future<Either<Failure, void>> resendOtp(String email) async {
    try {
      await authRemoteDatasource.resendOtp(email);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  // 🔥 MỚI: Triển khai Xác thực OTP
  @override
  Future<Either<Failure, void>> verifyOtp(String email, String otp, String purpose) async {
    try {
      await authRemoteDatasource.verifyOtp(email, otp, purpose);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> requestPasswordReset(String email) async {
    try {
      await authRemoteDatasource.requestPasswordReset(email);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String otp, String newPassword) async {
    try {
      await authRemoteDatasource.resetPassword(email, otp, newPassword);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  // 🔥 THÊM: Triển khai Refresh Token
  @override
  Future<Either<Failure, String>> refreshToken(String refreshToken) async {
    try {
      final result = await authRemoteDatasource.refreshToken(refreshToken);
      return Right(result);
    } on DioException catch (e) {
      return Left(UserFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await authRemoteDatasource.logout();
      return Right(null);
    } catch (e) {
      return Left(UserFailure(message: e.toString()));
    }
  }
}