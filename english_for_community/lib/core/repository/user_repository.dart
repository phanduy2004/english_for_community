import '../entity/user_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class UserRepository{
  Future<Either<Failure,UserEntity>> getProfile();
  Future<Either<Failure,UserEntity>> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? goal,
    String? cefr,
    int? dailyMinutes,
    Map<String, int>? reminder,
    bool? strictCorrection,
    String? language,
    String? timezone,
  });
  Future<Either<Failure,void>> deleteAccount();
}