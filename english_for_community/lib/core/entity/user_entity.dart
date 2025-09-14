import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'user_entity.g.dart';

/// Converter cho TimeOfDay <-> JSON.
/// Chấp nhận cả dạng {hour, minute} và fallback chuỗi "HH:mm".
class TimeOfDayConverter implements JsonConverter<TimeOfDay?, Object?> {
  const TimeOfDayConverter();

  @override
  TimeOfDay? fromJson(Object? json) {
    if (json == null) return null;

    if (json is Map<String, dynamic>) {
      final h = json['hour'];
      final m = json['minute'];
      if (h is int && m is int) {
        return TimeOfDay(hour: h, minute: m);
      }
    } else if (json is String) {
      final parts = json.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          return TimeOfDay(hour: h, minute: m);
        }
      }
    }
    return null;
  }

  @override
  Object? toJson(TimeOfDay? time) {
    if (time == null) return null;
    return {'hour': time.hour, 'minute': time.minute};
  }
}

@JsonSerializable()
class UserEntity extends Equatable {
  @JsonKey(name: 'id')
  final String id;
  final String fullName;
  final String email;
  final String username;

  final String? avatarUrl;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? bio;

  // NEW fields
  final String? goal;
  final String? cefr; // A1..C2
  final int? dailyMinutes;
  @TimeOfDayConverter()
  final TimeOfDay? reminder;
  final bool? strictCorrection;
  final String? language; // 'en', 'vi', ...
  final String? timezone; // 'Asia/Ho_Chi_Minh', ...

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.phone,
    this.dateOfBirth,
    this.bio,
    this.goal,
    this.cefr,
    this.dailyMinutes,
    this.reminder,
    this.strictCorrection,
    this.language,
    this.timezone,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UserEntityToJson(this);

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    username,
    avatarUrl,
    phone,
    dateOfBirth,
    bio,
    goal,
    cefr,
    dailyMinutes,
    reminder?.hour,
    reminder?.minute,
    strictCorrection,
    language,
    timezone,
  ];
}
