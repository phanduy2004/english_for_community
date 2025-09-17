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
  final String? bio;
  final String? avatarUrl;
  final String? goal;
  final String? cefr;
  final int? dailyMinutes;
  final Map<String, int>? reminder;
  final bool? strictCorrection;
  final String? language;
  final String? timezone;

  UpdateProfileEvent({this.fullName,  this.bio,  this.avatarUrl,  this.goal,  this.cefr,  this.dailyMinutes,  this.reminder,  this.strictCorrection,  this.language,  this.timezone});
}

class SignOutEvent extends UserEvent {}
