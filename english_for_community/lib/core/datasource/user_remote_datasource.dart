import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../entity/user_entity.dart';

class UserRemoteDatasource {
  final Dio dio;

  UserRemoteDatasource({required this.dio});

  Future<UserEntity> getProfile() async {
    final response = await dio.get('users/profile');
    return UserEntity.fromJson(response.data);
  }
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await dio.post('/users/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
  // 2. 🔥 API MỚI CHO ADMIN: Lấy chi tiết user khác (gồm cả Stats)
  Future<UserEntity> getUserById(String userId) async {
    // Gọi vào endpoint mới mà bạn vừa tạo ở Backend
    final response = await dio.get('users/$userId/admin-details');
    return UserEntity.fromJson(response.data);
  }
  Future<UserEntity> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    dynamic avatarFile, // File hoặc XFile
    String? goal,
    String? cefr,
    int? dailyMinutes,
    Map<String, int>? reminder,
    bool? strictCorrection,
    String? language,
    String? timezone,
    String? gender
  }) async {

    // 1. Tạo Map dữ liệu trước
    final Map<String, dynamic> mapData = {
      if (fullName != null) 'fullName': fullName,
      if (username != null) 'username': username,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
      if (bio != null) 'bio': bio,
      if (goal != null) 'goal': goal,
      if (cefr != null) 'cefr': cefr,
      if (dailyMinutes != null) 'dailyMinutes': dailyMinutes,
      if (strictCorrection != null) 'strictCorrection': strictCorrection,
      if (language != null) 'language': language,
      if (timezone != null) 'timezone': timezone,
      if (gender != null) 'gender': gender,

      // 🔥 SỬA LỖI Ở ĐÂY:
      // Luôn luôn gửi field 'reminder'.
      // - Nếu có dữ liệu -> Gửi JSON String
      // - Nếu là null -> Gửi chuỗi "null" để Backend biết mà xóa
      'reminder': reminder != null ? jsonEncode(reminder) : 'null',
    };

    // 2. Tạo FormData từ Map
    final formData = FormData.fromMap(mapData);

    // 3. Xử lý Avatar (Chỉ gửi nếu có file mới)
    if (avatarFile != null) {
      formData.files.add(MapEntry(
        'avatar',
        await MultipartFile.fromFile(avatarFile.path),
      ));
    }

    // 4. Gửi Request PUT
    final response = await dio.put(
      'users/profile',
      data: formData,
    );

    return UserEntity.fromJson(response.data);
  }

  Future<void> deleteAccount() async {
    await dio.delete('users/profile');
  }
  Future<UserEntity> getPublicProfile(String userId) async {
    final response = await dio.get('users/$userId/public');
    return UserEntity.fromJson(response.data);
  }
}