// lib/core/entity/dictation_attempt_entity.dart
import 'package:equatable/equatable.dart';

class DictationScore extends Equatable {
  final double? wer;           // 0..1
  final double? cer;           // 0..1
  final int? correctWords;
  final int? totalWords;

  const DictationScore({
    this.wer,
    this.cer,
    this.correctWords,
    this.totalWords,
  });

  factory DictationScore.fromJson(Map<String, dynamic> json) => DictationScore(
    wer: (json['wer'] as num?)?.toDouble(),
    cer: (json['cer'] as num?)?.toDouble(),
    correctWords: (json['correctWords'] as num?)?.toInt(),
    totalWords: (json['totalWords'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'wer': wer,
    'cer': cer,
    'correctWords': correctWords,
    'totalWords': totalWords,
  };

  DictationScore copyWith({
    double? wer,
    double? cer,
    int? correctWords,
    int? totalWords,
  }) {
    return DictationScore(
      wer: wer ?? this.wer,
      cer: cer ?? this.cer,
      correctWords: correctWords ?? this.correctWords,
      totalWords: totalWords ?? this.totalWords,
    );
  }

  @override
  List<Object?> get props => [wer, cer, correctWords, totalWords];
}

class DictationAttemptEntity extends Equatable {
  final String id;                 // _id/id
  final String? userId;            // ObjectId string
  final String? listeningId;       // ObjectId string
  final int? cueIdx;

  final String? userText;
  final String? userTextNorm;

  final DictationScore? score;     // { wer, cer, correctWords, totalWords }

  final int? playedMs;
  final DateTime? submittedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DictationAttemptEntity({
    required this.id,
    this.userId,
    this.listeningId,
    this.cueIdx,
    this.userText,
    this.userTextNorm,
    this.score,
    this.playedMs,
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory DictationAttemptEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null) {
      throw ArgumentError('DictationAttemptEntity.fromJson: missing id/_id');
    }
    return DictationAttemptEntity(
      id: id,
      userId: json['userId']?.toString(),
      listeningId: json['listeningId']?.toString(),
      cueIdx: (json['cueIdx'] as num?)?.toInt(),
      userText: json['userText'] as String?,
      userTextNorm: json['userTextNorm'] as String?,
      score: (json['score'] is Map<String, dynamic>)
          ? DictationScore.fromJson(json['score'] as Map<String, dynamic>)
          : null,
      playedMs: (json['playedMs'] as num?)?.toInt(),
      submittedAt: _parseDate(json['submittedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'listeningId': listeningId,
    'cueIdx': cueIdx,
    'userText': userText,
    'userTextNorm': userTextNorm,
    'score': score?.toJson(),
    'playedMs': playedMs,
    'submittedAt': submittedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  DictationAttemptEntity copyWith({
    String? id,
    String? userId,
    String? listeningId,
    int? cueIdx,
    String? userText,
    String? userTextNorm,
    DictationScore? score,
    int? playedMs,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DictationAttemptEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listeningId: listeningId ?? this.listeningId,
      cueIdx: cueIdx ?? this.cueIdx,
      userText: userText ?? this.userText,
      userTextNorm: userTextNorm ?? this.userTextNorm,
      score: score ?? this.score,
      playedMs: playedMs ?? this.playedMs,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    listeningId,
    cueIdx,
    userText,
    userTextNorm,
    score,
    playedMs,
    submittedAt,
    createdAt,
    updatedAt,
  ];
}
