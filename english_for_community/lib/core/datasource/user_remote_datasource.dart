import 'package:dio/dio.dart';

import '../entity/user_entity.dart';

class UserRemoteDatasource {
  final Dio dio;

  UserRemoteDatasource({required this.dio});

  Future<UserEntity> getProfile() async {
    final response = await dio.get('users/profile');
    return UserEntity.fromJson(response.data);
  }

  Future<UserEntity> updateProfile({
    required String fullName,
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
    final response = await dio.put(
      'users/profile',
      data: {
        'fullName': fullName,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'goal': goal,
        'cefr': cefr,
        'dailyMinutes': dailyMinutes,
        'reminder': reminder,
        'strictCorrection': strictCorrection,
        'language': language,
        'timezone': timezone,
      },
    );
    return UserEntity.fromJson(response.data);
  }

  Future<void> deleteAccount() async {
    await dio.delete('users/profile');
  }
}