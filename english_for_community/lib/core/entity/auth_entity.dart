// lib/core/entity/auth_entity.dart
import 'user_entity.dart'; // Import file UserEntity của bạn

class AuthEntity {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;

  const AuthEntity({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}