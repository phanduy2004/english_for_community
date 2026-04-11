// feature/history/data/model/activity_model.dart

enum ActivityType { writing, reading, speaking, listening, unknown }
enum ActivityStatus { completed, pending, reviewed, draft, unknown }

// 1. Class con để chứa thông tin User
class ActivityUser {
  final String id;
  final String name;
  final String avatar;
  final String email;

  ActivityUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.email,
  });

  factory ActivityUser.fromJson(Map<String, dynamic> json) {
    return ActivityUser(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      avatar: json['avatar'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

// 2. Class chính ActivityModel
class ActivityModel {
  final String id;
  final String title;
  final ActivityType type;
  final DateTime date;
  final double score;
  final int durationSeconds;

  // Metadata
  final ActivityStatus status;
  final int? wordCount;
  final int? correctCount;
  final int? totalQuestions;
  final String? subType;
  final List<String> tags;

  // 🔥 THÊM: Thông tin người dùng (cho Admin view)
  final ActivityUser? user;

  ActivityModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.score,
    required this.durationSeconds,
    required this.status,
    this.wordCount,
    this.correctCount,
    this.totalQuestions,
    this.subType,
    required this.tags,
    this.user, // 🔥 Thêm vào constructor
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Activity',
      type: _parseType(json['type']),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      score: (json['score'] ?? 0).toDouble(),
      durationSeconds: json['durationSeconds'] ?? 0,
      status: _parseStatus(json['status']),
      wordCount: json['wordCount'],
      correctCount: json['correctCount'],
      totalQuestions: json['totalQuestions'],
      subType: json['subType'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],

      // 🔥 Parse User object từ JSON backend trả về
      user: json['user'] != null ? ActivityUser.fromJson(json['user']) : null,
    );
  }

  static ActivityType _parseType(String? type) {
    switch (type) {
      case 'writing': return ActivityType.writing;
      case 'reading': return ActivityType.reading;
      case 'speaking': return ActivityType.speaking;
      case 'listening': return ActivityType.listening;
      default: return ActivityType.unknown;
    }
  }

  static ActivityStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed': return ActivityStatus.completed;
      case 'submitted': return ActivityStatus.pending;
      case 'reviewed': return ActivityStatus.reviewed;
      case 'draft': return ActivityStatus.draft;
      default: return ActivityStatus.completed;
    }
  }
}

/// Kết quả phân trang từ `GET /api/users/me/activities`
class ActivityHistoryListResult {
  final List<ActivityModel> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const ActivityHistoryListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });
}