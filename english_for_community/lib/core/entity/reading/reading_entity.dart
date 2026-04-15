import 'package:english_for_community/core/entity/reading/reading_progress_entity.dart';
import 'package:english_for_community/core/entity/reading/translation_entity.dart';
import 'package:equatable/equatable.dart';
import 'reading_feedback_entity.dart';

enum ReadingDifficulty { easy, medium, hard }

String? _difficultyToJson(ReadingDifficulty? v) {
  switch (v) {
    case ReadingDifficulty.easy:   return 'easy';
    case ReadingDifficulty.medium: return 'medium';
    case ReadingDifficulty.hard:   return 'hard';
    default: return null;
  }
}

ReadingDifficulty? _difficultyFromJson(Object? v) {
  switch (v) {
    case 'easy':   return ReadingDifficulty.easy;
    case 'medium': return ReadingDifficulty.medium;
    case 'hard':   return ReadingDifficulty.hard;
    default: return null;
  }
}

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}

class ReadingEntity extends Equatable {
  final String id;
  final String title;
  final String summary; // 👈 THÊM VÀO
  final String content;
  final TranslationEntity? translation; // 👈 2. THÊM TRƯỜNG
  final ReadingDifficulty? difficulty;
  final String? imageUrl;
  final int minutesToRead; // 👈 THÊM VÀO
  final List<ReadingQuestionEntity> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReadingProgressEntity? progress;
  final int attemptsCount;
  final String adminStatus;

  const ReadingEntity({
    required this.id,
    required this.title,
    required this.summary, // 👈 THÊM VÀO
    required this.content,
    this.translation,
    this.difficulty,
    this.imageUrl,
    required this.minutesToRead, // 👈 THÊM VÀO
    required this.questions,
    this.createdAt,
    this.updatedAt,
    this.progress,
    this.attemptsCount = 0,
    this.adminStatus = 'published',
  });

  factory ReadingEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null) {
      throw ArgumentError('ReadingEntity.fromJson: missing id/_id');
    }

    return ReadingEntity(
      id: id,
      title: (json['title'] ?? '') as String,
      summary: (json['summary'] ?? '') as String, // 👈 THÊM VÀO
      content: (json['content'] ?? '') as String,
      translation: json['translation'] != null
          ? TranslationEntity.fromJson(json['translation'] as Map<String, dynamic>)
          : null,
      difficulty: _difficultyFromJson(json['difficulty']),
      imageUrl: json['imageUrl'] as String?,
      minutesToRead: (json['minutesToRead'] as num? ?? 5).toInt(), // 👈 THÊM VÀO
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => ReadingQuestionEntity.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      progress: json['progress'] != null
          ? ReadingProgressEntity.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
      adminStatus: (json['adminStatus'] ?? 'published').toString(),
    );
  }

  // (toJson() và props cũng được cập nhật tương ứng)

  @override
  List<Object?> get props => [
    id, title, summary, content, translation, difficulty, imageUrl,
    minutesToRead, questions, createdAt, updatedAt, progress
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'content': content,
    'difficulty': _difficultyToJson(difficulty),
    'imageUrl': imageUrl,
    'minutesToRead': minutesToRead,
    'questions': questions.map((q) => q.toJson()).toList(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'progress': progress?.toJson(),
    'attemptsCount': attemptsCount,
    'adminStatus': adminStatus,
  };
}
class ReadingQuestionEntity extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final ReadingFeedbackEntity? feedback;
  final QuestionTranslationEntity? translation; // 👈 2. THÊM TRƯỜNG
  const ReadingQuestionEntity({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.feedback,
    this.translation,
  });

  factory ReadingQuestionEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null) {
      throw ArgumentError('ReadingQuestionEntity.fromJson: missing id/_id');
    }

    return ReadingQuestionEntity(
      id: id,
      questionText: (json['questionText'] ?? '') as String,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((opt) => opt.toString())
          .toList(),
      correctAnswerIndex: (json['correctAnswerIndex'] as num? ?? 0).toInt(),

      // 💡 4. PARSE OBJECT 'feedback'
      feedback: json['feedback'] != null
          ? ReadingFeedbackEntity.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
      translation: json['translation'] != null
          ? QuestionTranslationEntity.fromJson(json['translation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'feedback': feedback?.toJson(),
      'translation': translation?.toJson(),
    };

    // 💡 CHỈ GỬI _id NẾU NÓ CÓ GIÁ TRỊ HỢP LỆ
    if (id.isNotEmpty) {
      map['_id'] = id;
    }

    return map;
  }

  @override
  List<Object?> get props => [
    id,
    questionText,
    options,
    correctAnswerIndex,
    feedback,translation
  ];
}