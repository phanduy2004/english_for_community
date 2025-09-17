import 'package:dio/dio.dart';

import '../api/token_storage.dart';
import '../entity/user_entity.dart';

class AuthRemoteDatasource{
  final Dio dio;

  AuthRemoteDatasource({required this.dio});
  Future<UserEntity> login(String email, String password) async {
    final res = await dio.post('users/login', data: {
      'email': email,
      'password': password,
    });
    final token = res.data['token'] as String?;
    if (token != null) await TokenStorage.save(token);
    return UserEntity.fromJson(res.data['user']);
  }
  Future<void> logout() async {
    await TokenStorage.clear();
    // Tuỳ ý gọi API /logout nếu muốn
  }
}