import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/auth_remote_datasource.dart';
import 'package:english_for_community/core/entity/user_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';

import '../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource authRemoteDatasource;

  AuthRepositoryImpl({required this.authRemoteDatasource});

  @override
  Future<Either<Failure, UserEntity>> login( String email,
      String password) async {
    try {
       return Right(await authRemoteDatasource.login(email, password));
    }
    on DioException catch(e){
      return Left(AuthFailure(message: e.response?.data['message']));
    }catch (e){
      return Left(AuthFailure(message: e.toString()));

    }
  }

}