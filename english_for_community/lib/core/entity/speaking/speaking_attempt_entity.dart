// lib/core/entity/speaking_attempt_entity.dart
import 'package:equatable/equatable.dart';

// Helper class cho trường 'score' (Giữ nguyên)
class SpeakingScoreEntity extends Equatable {
  final double wer;
  final double confidence;

  const SpeakingScoreEntity({required this.wer, required this.confidence});

  factory SpeakingScoreEntity.fromJson(Map<String, dynamic> json) {
    return SpeakingScoreEntity(
      wer: (json['wer'] as num?)?.toDouble() ?? 1.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wer': wer,
      'confidence': confidence,
    };
  }

  @override
  List<Object?> get props => [wer, confidence];
}


// ⬇️ SỬA CLASS NÀY ⬇️

class SpeakingAttemptEntity extends Equatable {
  final String? id;
  final String sentenceId;
  final String? userTranscript;
  final String? userAudioUrl;
  final SpeakingScoreEntity? score;
  final DateTime? submittedAt; // Đổi tên từ createdAt

  final int? audioDurationSeconds; // <-- ĐÃ THÊM

  const SpeakingAttemptEntity({
    this.id,
    required this.sentenceId,
    this.userTranscript,
    this.userAudioUrl,
    this.score,
    this.submittedAt,
    this.audioDurationSeconds, // <-- ĐÃ THÊM
  });

  factory SpeakingAttemptEntity.fromJson(Map<String, dynamic> json) {

    final id = json['id'] as String? ?? json['_id'] as String?;

    SpeakingScoreEntity? score;
    if (json['score'] != null) {
      score = SpeakingScoreEntity.fromJson(json['score'] as Map<String, dynamic>);
    } else if (json['wer'] != null) {
      score = SpeakingScoreEntity(
        wer: (json['wer'] as num).toDouble(),
        confidence: 0.0,
      );
    }

    return SpeakingAttemptEntity(
      id: id,
      sentenceId: json['sentenceId'] as String,
      userTranscript: json['userTranscript'] as String?,
      userAudioUrl: json['userAudioUrl'] as String?,
      score: score,
      submittedAt: _parseDate(json['submittedAt'] ?? json['createdAt']),
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(), // <-- ĐÃ THÊM
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sentenceId': sentenceId,
    'userTranscript': userTranscript,
    'userAudioUrl': userAudioUrl,
    'score': score?.toJson(),
    'submittedAt': submittedAt?.toIso8601String(),
    'audioDurationSeconds': audioDurationSeconds, // <-- ĐÃ THÊM
  };

  // Helper (giữ nguyên)
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
    sentenceId,
    userTranscript,
    userAudioUrl,
    score,
    submittedAt,
    audioDurationSeconds, // <-- ĐÃ THÊM
  ];
}