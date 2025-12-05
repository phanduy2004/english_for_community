import 'dart:io';

abstract class UserEvent {}

class LoginEvent extends UserEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}

class GetProfileEvent extends UserEvent {}

class DeleteAccountEvent extends UserEvent {}

class UpdateProfileEvent extends UserEvent {
  final String? fullName;
  final String? username;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? bio;
  final File? avatarFile; // Chỉ cần 1 trường File
  final String? goal;
  final String? cefr;
  final int? dailyMinutes;
  final Map<String, int>? reminder;
  final bool? strictCorrection;
  final String? language;
  final String? timezone;
  final String? gender;
  UpdateProfileEvent({
    this.fullName,
    this.username,
    this.phone,
    this.dateOfBirth,
    this.bio,
    this.avatarFile,
    this.goal,
    this.cefr,
    this.dailyMinutes,
    this.reminder,
    this.strictCorrection,
    this.language,
    this.timezone, this.gender,
  });
}

class SignOutEvent extends UserEvent {}
class CheckAuthStatusEvent extends UserEvent {}
class ForceLogoutEvent extends UserEvent {
  final String reason;
  ForceLogoutEvent({required this.reason});
}
// 🔥 EVENT MỚI: Đăng ký
class SignUpEvent extends UserEvent {
  final String email;
  final String password;
  final String fullName;
  final String username;
  final String? phone;
  final DateTime? dateOfBirth;

  SignUpEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
    this.phone,
    this.dateOfBirth,
  });
}
class ResendOtpEvent extends UserEvent {
  final String email;
  ResendOtpEvent({required this.email});
}
class VerifyOtpEvent extends UserEvent {
  final String email;
  final String otp;
  final String purpose; // 'signup', 'forgot'

  VerifyOtpEvent({
    required this.email,
    required this.otp,
    required this.purpose,
  });
}
class RequestForgotPasswordEvent extends UserEvent {
final String email;

RequestForgotPasswordEvent({required this.email});
}

class ResetPasswordEvent extends UserEvent {
final String email;
final String otp;
final String newPassword;

ResetPasswordEvent({
required this.email,
required this.otp,
required this.newPassword,
});
}

class RefreshTokenEvent extends UserEvent {
final String refreshToken;

RefreshTokenEvent({required this.refreshToken});
}
class ClearUserDataEvent extends UserEvent {}