import 'package:equatable/equatable.dart';

// --- Helper Functions (giống style của bạn) ---
enum ProgressStatus { notStarted, inProgress, completed }

ProgressStatus _statusFromJson(String? val, {ProgressStatus def = ProgressStatus.notStarted}) {
  switch (val) {
    case 'in_progress': return ProgressStatus.inProgress;
    case 'completed':   return ProgressStatus.completed;
    default:            return def;
  }
}

String _statusToJson(ProgressStatus val) {
  switch (val) {
    case ProgressStatus.inProgress: return 'in_progress';
    case ProgressStatus.completed:  return 'completed';
    default:                        return 'not_started';
  }
}

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}
// --- Hết Helper ---

class ReadingProgressEntity extends Equatable {
  final String id;
  final String userId;
  final String readingId;
  final ProgressStatus status;
  final double highScore;
  final int attemptsCount;
  final DateTime? lastAttemptedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReadingProgressEntity({
    required this.id,
    required this.userId,
    required this.readingId,
    this.status = ProgressStatus.notStarted,
    this.highScore = 0.0,
    this.attemptsCount = 0,
    this.lastAttemptedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ReadingProgressEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null) {
      throw ArgumentError('ReadingProgressEntity.fromJson: missing id/_id');
    }

    return ReadingProgressEntity(
      id: id,
      userId: (json['userId'] ?? '').toString(),
      readingId: (json['readingId'] ?? '').toString(),
      status: _statusFromJson(json['status'] as String?),
      highScore: (json['highScore'] as num?)?.toDouble() ?? 0.0,
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
      lastAttemptedAt: _parseDate(json['lastAttemptedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'readingId': readingId,
    'status': _statusToJson(status),
    'highScore': highScore,
    'attemptsCount': attemptsCount,
    'lastAttemptedAt': lastAttemptedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id, userId, readingId, status, highScore,
    attemptsCount, lastAttemptedAt, createdAt, updatedAt
  ];
}