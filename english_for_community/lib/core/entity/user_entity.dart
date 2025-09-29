import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Converter TimeOfDay dùng thủ công
class TimeOfDayConverter {
  const TimeOfDayConverter();
  TimeOfDay? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      final h = json['hour'];
      final m = json['minute'];
      if (h is int && m is int) return TimeOfDay(hour: h, minute: m);
    } else if (json is String) {
      final parts = json.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
      }
    }
    return null;
  }

  Object? toJson(TimeOfDay? time) {
    if (time == null) return null;
    return {'hour': time.hour, 'minute': time.minute};
  }
}

class UserEntity extends Equatable {
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

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final _id = (json['id'] ?? json['_id']) as String?;
    if (_id == null) {
      throw ArgumentError('UserEntity.fromJson: missing id/_id');
    }
    final _conv = const TimeOfDayConverter();
    return UserEntity(
      id: _id,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: _parseDate(json['dateOfBirth']),
      bio: json['bio'] as String?,
      goal: json['goal'] as String?,
      cefr: json['cefr'] as String?,
      dailyMinutes: (json['dailyMinutes'] as num?)?.toInt(),
      reminder: _conv.fromJson(json['reminder']),
      strictCorrection: _parseBool(json['strictCorrection']),
      language: json['language'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final _conv = const TimeOfDayConverter();
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bio': bio,
      'goal': goal,
      'cefr': cefr,
      'dailyMinutes': dailyMinutes,
      'reminder': _conv.toJson(reminder),
      'strictCorrection': strictCorrection,
      'language': language,
      'timezone': timezone,
    };
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  static bool? _parseBool(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == 'true' || v == '1';
    return null;
  }

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
