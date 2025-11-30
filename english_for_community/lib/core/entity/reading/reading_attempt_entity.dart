import 'package:equatable/equatable.dart';

DateTime? _parseDate(Object? v) {
  // ... (Nội dung hàm giữ nguyên)
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}

class ReadingAttemptEntity extends Equatable {
  final String id;
  final String userId;
  final String readingId;

  final List<AnswerDetailEntity> answers;

  final double score;
  final int correctCount;
  final int totalQuestions;
  final int? durationInSeconds; // <-- ĐÃ THÊM
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReadingAttemptEntity({
    required this.id,
    required this.userId,
    required this.readingId,
    required this.answers,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    this.durationInSeconds, // <-- ĐÃ THÊM
    this.createdAt,
    this.updatedAt,
  });

  factory ReadingAttemptEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null) {
      throw ArgumentError('ReadingAttemptEntity.fromJson: missing id/_id');
    }

    return ReadingAttemptEntity(
      id: id,
      userId: (json['userId'] ?? '').toString(),
      readingId: (json['readingId'] ?? '').toString(),

      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((a) => AnswerDetailEntity.fromJson(a as Map<String, dynamic>))
          .toList(),

      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      durationInSeconds: (json['durationInSeconds'] as num?)?.toInt(), // <-- ĐÃ THÊM
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'readingId': readingId,
    'answers': answers.map((a) => a.toJson()).toList(),
    'score': score,
    'correctCount': correctCount,
    'totalQuestions': totalQuestions,
    'durationInSeconds': durationInSeconds, // <-- ĐÃ THÊM
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id, userId, readingId, answers, score,
    correctCount, totalQuestions, durationInSeconds, // <-- ĐÃ THÊM
    createdAt, updatedAt
  ];
}


// Class con (giữ nguyên)
class AnswerDetailEntity extends Equatable {
  // ... (Nội dung class giữ nguyên)
  final String questionId;
  final int chosenIndex;
  final bool isCorrect;

  const AnswerDetailEntity({
    required this.questionId,
    required this.chosenIndex,
    required this.isCorrect,
  });

  factory AnswerDetailEntity.fromJson(Map<String, dynamic> json) {
    return AnswerDetailEntity(
      questionId: (json['questionId'] ?? '').toString(),
      chosenIndex: (json['chosenIndex'] as num? ?? -1).toInt(),
      isCorrect: (json['isCorrect'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'chosenIndex': chosenIndex,
    'isCorrect': isCorrect,
  };

  @override
  List<Object?> get props => [questionId, chosenIndex, isCorrect];
}