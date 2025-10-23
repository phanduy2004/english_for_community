// core/repository/cue_repository.dart
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';

import '../entity/cue_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

/// Kết quả submit một cue.
/// - [passed]: BE quyết định qua/không (so khớp toàn câu sau normalize)
/// - [wer], [cer]: chỉ để hiển thị/thống kê
/// - [maskedHint]: BE có thể trả gợi ý "đến từ sai + *****" (nullable).
///   FE KHÔNG phụ thuộc trường này vì đã tự tính được hint từ (refText, userText).
class SubmitResult {
  final bool passed;
  final double wer;
  final double cer;
  final String? maskedHint;

  const SubmitResult({
    required this.passed,
    required this.wer,
    required this.cer,
    this.maskedHint,
  });

  SubmitResult copyWith({
    bool? passed,
    double? wer,
    double? cer,
    String? maskedHint,
  }) {
    return SubmitResult(
      passed: passed ?? this.passed,
      wer: wer ?? this.wer,
      cer: cer ?? this.cer,
      maskedHint: maskedHint ?? this.maskedHint,
    );
  }

  factory SubmitResult.empty() => const SubmitResult(passed: false, wer: 1.0, cer: 1.0);

  /// Hỗ trợ parse từ BE:
  /// {
  ///   "passed": true/false,
  ///   "score": {"wer": 0.0, "cer": 0.0, ...},
  ///   "hint": {"maskedSuggestion": "Wake up, it's *****"}
  /// }
  factory SubmitResult.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as Map?) ?? const {};
    final hint  = (json['hint']  as Map?) ?? const {};
    return SubmitResult(
      passed: (json['passed'] as bool?) ?? false,
      wer: (score['wer'] as num?)?.toDouble() ?? 1.0,
      cer: (score['cer'] as num?)?.toDouble() ?? 1.0,
      maskedHint: hint['maskedSuggestion'] as String?,
    );
  }
}

abstract class CueRepository {
  Future<Either<Failure, List<CueEntity>>> getCuesByListeningId(
      String listeningId, {
        int from = 0,
        int limit = 200,
      });

  /// Submit đáp án cho cue hiện tại.
  /// Trả về [SubmitResult]; FE dùng:
  ///  - result.passed để quyết định Next
  ///  - result.maskedHint (nếu muốn), nhưng mặc định FE sẽ tự build hint local
  Future<Either<Failure, SubmitResult>> submitCue({
    required String listeningId,
    required int cueIdx,
    required String userText,
    int? playedMs,
  });

  Future<Either<Failure, List<DictationAttemptEntity>>> listDictationAttempt(
      String listeningId,
      );
}
