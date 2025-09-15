
import '../entity/user_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure,UserEntity>> login(String email, String password);

}