import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Converter to switch between Object {hour, minute} from API and Flutter's TimeOfDay
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
  // === BASIC FIELDS ===
  final String id;
  final String fullName;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? bio;

  // 🔥 THÊM: Gender
  final String? gender;

  // 🔥 THÊM: Xác thực email
  final bool isVerified;

  // 🔥 IMPORTANT: Permissions & Status
  final String role;

  // === BAN STATUS ===
  final bool isBanned;
  final String? banReason;
  final DateTime? banExpiresAt;

  // === LEARNING CONFIG ===
  final String? goal;
  final String? cefr;
  final int? dailyMinutes;
  final TimeOfDay? reminder;
  final bool? strictCorrection;
  final String? language;
  final String? timezone;

  // === GAMIFICATION ===
  final int? dailyActivityGoal;
  final int? dailyActivityProgress;
  final String? dailyProgressDate;

  final int? totalPoints;
  final int? level;
  final int? currentStreak;

  // === ONLINE STATUS ===
  final bool isOnline;
  final DateTime? lastActivityDate;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.phone,
    this.dateOfBirth,
    this.bio,

    // 🔥 THÊM: Default null cho gender
    this.gender,

    // 🔥 THÊM: Default false cho isVerified
    this.isVerified = false,

    this.role = 'user',
    // Ban fields
    this.isBanned = false,
    this.banReason,
    this.banExpiresAt,
    // Config
    this.goal,
    this.cefr,
    this.dailyMinutes,
    this.reminder,
    this.strictCorrection,
    this.language,
    this.timezone,
    // Gamification
    this.dailyActivityGoal,
    this.dailyActivityProgress,
    this.dailyProgressDate,
    this.totalPoints,
    this.level,
    this.currentStreak,
    // Online status
    this.isOnline = false,
    this.lastActivityDate,
  });

  // 🔥 ADDED COPYWITH METHOD HERE
  UserEntity copyWith({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    String? goal,
    String? cefr,
    int? dailyMinutes,

    // 🔥 THÊM: Copy gender và isVerified
    String? gender,
    bool? isVerified,

    // Logic for Reminder
    TimeOfDay? reminder,
    bool clearReminder = false, // ✅ Flag to force clear reminder

    bool? strictCorrection,
    String? language,
    String? timezone,
    int? dailyActivityGoal,
    int? dailyActivityProgress,
    int? currentStreak,
    int? totalPoints,
    int? level,
  }) {
    return UserEntity(
      id: this.id, // ID usually doesn't change
      email: this.email, // Email usually doesn't change via profile update
      role: this.role,
      isBanned: this.isBanned,
      banReason: this.banReason,
      banExpiresAt: this.banExpiresAt,

      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      goal: goal ?? this.goal,
      cefr: cefr ?? this.cefr,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,

      // ✅ Logic: If clearReminder is true -> set null. Otherwise use new value or keep old.
      reminder: clearReminder ? null : (reminder ?? this.reminder),

      strictCorrection: strictCorrection ?? this.strictCorrection,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,

      // 🔥 THÊM: Copy gender và isVerified
      gender: gender ?? this.gender,
      isVerified: isVerified ?? this.isVerified,

      dailyActivityGoal: dailyActivityGoal ?? this.dailyActivityGoal,
      dailyActivityProgress: dailyActivityProgress ?? this.dailyActivityProgress,
      dailyProgressDate: this.dailyProgressDate,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,

      isOnline: this.isOnline,
      lastActivityDate: this.lastActivityDate,
    );
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final _id = (json['id'] ?? json['_id']) as String?;
    if (_id == null) {
      return const UserEntity(
          id: '',
          fullName: 'Unknown',
          email: '',
          username: ''
      );
    }

    const conv = TimeOfDayConverter();

    bool onlineStatus = false;
    if (json['isOnline'] != null) {
      onlineStatus = json['isOnline'] as bool;
    } else if (json['status'] != null && json['status'] is Map) {
      onlineStatus = json['status']['isOnline'] ?? false;
    }

    return UserEntity(
      id: _id,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: _parseDate(json['dateOfBirth']),
      bio: json['bio'] as String?,

      // 🔥 THÊM: Parse gender và isVerified
      gender: json['gender'] as String?,
      isVerified: json['isVerified'] ?? false,

      role: json['role'] ?? 'user',

      isBanned: json['isBanned'] ?? false,
      banReason: json['banReason'] as String?,
      banExpiresAt: _parseDate(json['banExpiresAt']),

      goal: json['goal'] as String?,
      cefr: json['cefr'] as String?,
      dailyMinutes: (json['dailyMinutes'] as num?)?.toInt(),
      reminder: conv.fromJson(json['reminder']),
      strictCorrection: _parseBool(json['strictCorrection']),
      language: json['language'] as String?,
      timezone: json['timezone'] as String?,

      dailyActivityGoal: (json['dailyActivityGoal'] as num?)?.toInt() ?? 5,
      dailyActivityProgress: (json['dailyActivityProgress'] as num?)?.toInt() ?? 0,
      dailyProgressDate: json['dailyProgressDate'] as String?,

      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,

      isOnline: onlineStatus,
      lastActivityDate: _parseDate(json['lastActivityDate']),
    );
  }

  Map<String, dynamic> toJson() {
    const conv = TimeOfDayConverter();
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bio': bio,

      // 🔥 THÊM: toJson cho gender và isVerified
      'gender': gender,
      'isVerified': isVerified,

      'role': role,
      'isBanned': isBanned,
      'banReason': banReason,
      'banExpiresAt': banExpiresAt?.toIso8601String(),
      'goal': goal,
      'cefr': cefr,
      'dailyMinutes': dailyMinutes,
      'reminder': conv.toJson(reminder),
      'strictCorrection': strictCorrection,
      'language': language,
      'timezone': timezone,
      'dailyActivityGoal': dailyActivityGoal,
      'dailyActivityProgress': dailyActivityProgress,
      'totalPoints': totalPoints,
      'level': level,
      'currentStreak': currentStreak,
      'isOnline': isOnline,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  static bool? _parseBool(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  @override
  List<Object?> get props => [
    id, fullName, email, username, avatarUrl, phone,
    role, isBanned, banReason, banExpiresAt,
    dailyActivityGoal, dailyActivityProgress, totalPoints, level, currentStreak,
    reminder, timezone,
    isOnline, lastActivityDate,

    // 🔥 THÊM: Props cho gender và isVerified
    gender, isVerified,
  ];
}