import 'package:dio/dio.dart';

import '../entity/user_entity.dart';

class AuthRemoteDatasource{
  final Dio dio;

  AuthRemoteDatasource({required this.dio});
  Future<UserEntity> login(String email, String password) async {
    final response = await dio.post(
      'users/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return UserEntity.fromJson(response.data);
  }
}