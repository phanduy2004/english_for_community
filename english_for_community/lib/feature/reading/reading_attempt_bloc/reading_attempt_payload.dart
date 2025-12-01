
class AnswerPayload {
  final String questionId;
  final int chosenIndex;
  final bool isCorrect;

  AnswerPayload({
    required this.questionId,
    required this.chosenIndex,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'chosenIndex': chosenIndex,
    'isCorrect': isCorrect,
  };
}

/// Payload tổng cho TOÀN BỘ lần nộp bài
class ReadingAttemptPayload {
  final String readingId;
  final List<AnswerPayload> answers;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int durationInSeconds; // <-- THÊM DÒNG NÀY
  ReadingAttemptPayload({
    required this.readingId,
    required this.answers,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.durationInSeconds,
  });

  /// Convert object Dart thành JSON để gửi đi
  Map<String, dynamic> toJson() => {
    'readingId': readingId,
    'answers': answers.map((a) => a.toJson()).toList(),
    'score': score,
    'correctCount': correctCount,
    'totalQuestions': totalQuestions,
    'durationInSeconds': durationInSeconds,
  };
}