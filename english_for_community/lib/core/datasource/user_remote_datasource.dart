import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../entity/user_entity.dart';

Future<MultipartFile> _avatarMultipart(XFile avatarFile) async {
  final bytes = await avatarFile.readAsBytes();
  final name = avatarFile.name.trim().isNotEmpty ? avatarFile.name : 'avatar.jpg';
  return MultipartFile.fromBytes(bytes, filename: name);
}

class UserRemoteDatasource {
  final Dio dio;

  UserRemoteDatasource({required this.dio});
  Future<void> triggerTestNotification() async {
    await dio.post('/users/test-notification');
  }
  Future<void> updateFcmToken(String token) async {
    await dio.post('/users/fcm-token', data: {'token': token});
  }
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
    XFile? avatarFile,
    String? goal,
    String? cefr,
    int? dailyMinutes,
    Map<String, int>? reminder,
    int? dailyLessonGoal, // 🔥 THÊM THAM SỐ
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
      if (dailyLessonGoal != null) 'dailyLessonGoal': dailyLessonGoal, // 🔥 THÊM DỮ LIỆU

    };

    // 2. Tạo FormData từ Map
    final formData = FormData.fromMap(mapData);

    // 3. Avatar — XFile/bytes on web (File.path throws UnsupportedError on web)
    if (avatarFile != null) {
      formData.files.add(MapEntry('avatar', await _avatarMultipart(avatarFile)));
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