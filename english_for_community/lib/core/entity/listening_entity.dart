import 'package:equatable/equatable.dart';
// Import LessonEntity của bạn
import 'cue_entity.dart';

// --- Helper Classes ---
class PlaybackPad extends Equatable {
  final int? before;
  final int? after;
  const PlaybackPad({this.before, this.after});

  factory PlaybackPad.fromJson(Map<String, dynamic> json) => PlaybackPad(
    before: (json['before'] as num?)?.toInt(),
    after: (json['after'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {'before': before, 'after': after};

  @override
  List<Object?> get props => [before, after];
}

enum ListeningDifficulty { easy, medium, hard }

String? _difficultyToJson(ListeningDifficulty? v) {
  switch (v) {
    case ListeningDifficulty.easy: return 'easy';
    case ListeningDifficulty.medium: return 'medium';
    case ListeningDifficulty.hard: return 'hard';
    default: return null;
  }
}

ListeningDifficulty? _difficultyFromJson(Object? v) {
  switch (v) {
    case 'easy': return ListeningDifficulty.easy;
    case 'medium': return ListeningDifficulty.medium;
    case 'hard': return ListeningDifficulty.hard;
    default: return null;
  }
}

// --- Main Entity ---
class ListeningEntity extends Equatable {
  final String id;
  final String? code;
  final String title;
  final String audioUrl;
  final PlaybackPad? playbackPad;
  final ListeningDifficulty? difficulty;
  final String? cefr;
  final List<String>? tags;
  final int? totalCues;     // Tổng số cue (đôi khi backend trả về số lượng để hiển thị nhanh)
  final String? transcript; // Script gộp
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double userProgress;
  final List<CueEntity> cues; // 👈 Danh sách Cue đã được nhúng vào

  const ListeningEntity({
    required this.id,
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
    this.userProgress = 0.0,
    this.cues = const [],
  });

  factory ListeningEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null) {
      throw ArgumentError('ListeningEntity.fromJson: missing id/_id');
    }

    // Parse LessonId (như cũ)


    return ListeningEntity(
      id: id,
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
      userProgress: (json['userProgress'] as num?)?.toDouble() ?? 0.0,

      // 👇 Map mảng cues từ JSON
      cues: (json['cues'] as List<dynamic>?)
          ?.map((e) => CueEntity.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
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
      'userProgress': userProgress,
      // 👇 Serialize mảng cues gửi lên backend
      'cues': cues.map((e) => e.toJson()).toList(),
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  ListeningEntity copyWith({
    String? id,
    String? title,
    String? code,
    String? audioUrl,
    String? cefr,
    ListeningDifficulty? difficulty,
    List<CueEntity>? cues,
    int? totalCues,
    PlaybackPad? playbackPad,
    List<String>? tags,
    String? transcript,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? userProgress,
  }) {
    return ListeningEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      audioUrl: audioUrl ?? this.audioUrl,
      cefr: cefr ?? this.cefr,
      difficulty: difficulty ?? this.difficulty,
      cues: cues ?? this.cues,
      totalCues: totalCues ?? this.totalCues,
      playbackPad: playbackPad ?? this.playbackPad,
      tags: tags ?? this.tags,
      transcript: transcript ?? this.transcript,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userProgress: userProgress ?? this.userProgress,
    );
  }

  @override
  List<Object?> get props => [
    id, code, title, audioUrl, playbackPad, difficulty, cefr,
    tags, totalCues, transcript, createdAt, updatedAt, userProgress, cues
  ];
}