// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserEntity _$UserEntityFromJson(Map<String, dynamic> json) => UserEntity(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  phone: json['phone'] as String?,
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
  bio: json['bio'] as String?,
  goal: json['goal'] as String?,
  cefr: json['cefr'] as String?,
  dailyMinutes: (json['dailyMinutes'] as num?)?.toInt(),
  reminder: const TimeOfDayConverter().fromJson(json['reminder']),
  strictCorrection: json['strictCorrection'] as bool?,
  language: json['language'] as String?,
  timezone: json['timezone'] as String?,
);

Map<String, dynamic> _$UserEntityToJson(UserEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'phone': instance.phone,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'bio': instance.bio,
      'goal': instance.goal,
      'cefr': instance.cefr,
      'dailyMinutes': instance.dailyMinutes,
      'reminder': const TimeOfDayConverter().toJson(instance.reminder),
      'strictCorrection': instance.strictCorrection,
      'language': instance.language,
      'timezone': instance.timezone,
    };
