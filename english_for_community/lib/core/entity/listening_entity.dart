import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/lesson_entity.dart';

class PlaybackPad extends Equatable {
  final int? before; // ms
  final int? after;  // ms
  const PlaybackPad({this.before, this.after});

  factory PlaybackPad.fromJson(Map<String, dynamic> json) => PlaybackPad(
    before: (json['before'] as num?)?.toInt(),
    after:  (json['after']  as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {'before': before, 'after': after};

  @override
  List<Object?> get props => [before, after];
}

enum ListeningDifficulty { easy, medium, hard }

String? _difficultyToJson(ListeningDifficulty? v) {
  switch (v) {
    case ListeningDifficulty.easy:   return 'easy';
    case ListeningDifficulty.medium: return 'medium';
    case ListeningDifficulty.hard:   return 'hard';
    default: return null;
  }
}

ListeningDifficulty? _difficultyFromJson(Object? v) {
  switch (v) {
    case 'easy':   return ListeningDifficulty.easy;
    case 'medium': return ListeningDifficulty.medium;
    case 'hard':   return ListeningDifficulty.hard;
    default: return null;
  }
}

class ListeningEntity extends Equatable {
  final String id;                     // id/_id
  final LessonEntity lessonId;         // <-- object (theo đúng tên bạn đã dùng)
  final String? code;
  final String title;
  final String audioUrl;
  final PlaybackPad? playbackPad;
  final ListeningDifficulty? difficulty;
  final String? cefr;
  final List<String>? tags;
  final int? totalCues;
  final String? transcript;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ListeningEntity({
    required this.id,
    required this.lessonId,
    this.code,
    required this.title,
    required this.audioUrl,
    this.playbackPad,
    this.difficulty,
    this.cefr,
    this.tags,
    this.totalCues,
    this.transcript,
    this.createdAt,
    this.updatedAt,
  });

  factory ListeningEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'])?.toString();
    if (id == null) {
      throw ArgumentError('ListeningEntity.fromJson: missing id/_id');
    }

    // Accept "lesson" or "lessonId" as OBJECT. Reject string id to keep contract strict.
    final rawLesson = json['lesson'] ?? json['lessonId'];
    if (rawLesson is! Map<String, dynamic>) {
      throw ArgumentError(
          'ListeningEntity.fromJson: expected lesson/lessonId to be an OBJECT, got: ${rawLesson.runtimeType}. '
              'Please make backend return populated object for lesson.'
      );
    }

    return ListeningEntity(
      id: id,
      lessonId: LessonEntity.fromJson(rawLesson as Map<String, dynamic>),
      code: json['code'] as String?,
      title: (json['title'] ?? '') as String,
      audioUrl: (json['audioUrl'] ?? '') as String,
      playbackPad: (json['playbackPad'] is Map<String, dynamic>)
          ? PlaybackPad.fromJson(json['playbackPad'] as Map<String, dynamic>)
          : null,
      difficulty: _difficultyFromJson(json['difficulty']),
      cefr: json['cefr'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      totalCues: (json['totalCues'] as num?)?.toInt(),
      transcript: json['transcript'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lesson': lessonId.toJson(), // gửi cả object (thống nhất contract)
    'code': code,
    'title': title,
    'audioUrl': audioUrl,
    'playbackPad': playbackPad?.toJson(),
    'difficulty': _difficultyToJson(difficulty),
    'cefr': cefr,
    'tags': tags,
    'totalCues': totalCues,
    'transcript': transcript,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  @override
  List<Object?> get props => [
    id, lessonId, code, title, audioUrl, playbackPad, difficulty, cefr, tags, totalCues, transcript, createdAt, updatedAt,
  ];
}
