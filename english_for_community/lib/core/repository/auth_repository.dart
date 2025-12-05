
import '../entity/auth_entity.dart';
import '../entity/user_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? dateOfBirth,
  });
  Future<Either<Failure, void>> resendOtp(String email);
  Future<Either<Failure, void>> verifyOtp(String email, String otp, String purpose);
  Future<Either<Failure, void>> requestPasswordReset(String email);
  Future<Either<Failure, void>> resetPassword(String email, String otp, String newPassword);
  Future<Either<Failure, String>> refreshToken(String refreshToken);

}