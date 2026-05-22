import 'package:image_picker/image_picker.dart';

import '../entity/user_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> updateFcmToken(String token);
  Future<Either<Failure, UserEntity>> getProfile();
  Future<Either<Failure, void>> triggerTestNotification();
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    XFile? avatarFile,
    String? goal,
    String? cefr, // ✅ Đảm bảo tên là cefr
    int? dailyMinutes,
    int? dailyLessonGoal, // ✅ Thêm tham số này
    Map<String, int>? reminder,
    bool? strictCorrection,
    String? language,
    String? timezone,
    String? gender,
  });
  Future<Either<Failure, UserEntity>> getPublicProfile(String userId);
  Future<Either<Failure, void>> deleteAccount();
  Future<Either<Failure, UserEntity>> getUserById(String id);
  Future<Either<Failure, void>> changePassword(String currentPassword, String newPassword);
}