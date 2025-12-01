// lib/core/datasource/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import '../api/token_storage.dart'; // Giả sử file này nằm trong /api
import '../entity/user_entity.dart';

class AuthRemoteDatasource {
  final Dio dio;

  AuthRemoteDatasource({required this.dio});

  Future<UserEntity> login(String email, String password) async {
    // Đảm bảo endpoint này khớp với auth_routes.js (vd: 'auth/login')
    final res = await dio.post('auth/login', data: {
      'email': email,
      'password': password,
    });

    final accessToken = res.data['accessToken'] as String?;
    final refreshToken = res.data['refreshToken'] as String?;

    // ✅ SỬA: Kiểm tra kỹ null trước khi lưu
    if (accessToken == null || refreshToken == null) {
      throw Exception('Login failed: Tokens not provided from server');
    }

    // 1. Lưu cả 2 token
    await TokenStorage.saveAccessToken(accessToken);
    await TokenStorage.saveRefreshToken(refreshToken);

    // 2. Trả về user
    return UserEntity.fromJson(res.data['user']);
  }

  Future<void> logout() async {
    try {
      await dio.post('auth/logout');
    } catch (e) {
      print('Error calling logout API, proceeding with local clear: $e');
    }
    await TokenStorage.clearAllTokens();
  }
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    await dio.post('auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    });
  }

  Future<void> resendOtp(String email) async {
    await dio.post('auth/register/resend-otp', data: {'email': email});
  }

  Future<void> verifyOtp(String email, String otp, String purpose) async {
    await dio.post('auth/verify-otp', data: {
      'email': email,
      'otp': otp,
      'purpose': purpose,
    });
  }
  Future<void> requestPasswordReset(String email) async {
    await dio.post('auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await dio.post('auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<String> refreshToken(String refreshToken) async {
    final res = await dio.post('auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    final newAccessToken = res.data['accessToken'] as String?;
    if (newAccessToken == null) {
      throw Exception('Refresh failed: New access token not provided');
    }
    await TokenStorage.saveAccessToken(newAccessToken);
    return newAccessToken;
  }
}