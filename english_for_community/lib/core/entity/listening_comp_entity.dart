import 'package:equatable/equatable.dart';

class ListeningCompFeedbackEntity extends Equatable {
  final String reasoning;
  final int? hintTimestampSeconds;
  final String? keySentence;

  const ListeningCompFeedbackEntity({required this.reasoning, this.hintTimestampSeconds, this.keySentence});

  factory ListeningCompFeedbackEntity.fromJson(Map<String, dynamic> json) => ListeningCompFeedbackEntity(
    reasoning: json['reasoning'] ?? '',
    hintTimestampSeconds: json['hintTimestampSeconds'],
    keySentence: json['keySentence'],
  );

  @override
  List<Object?> get props => [reasoning, hintTimestampSeconds, keySentence];
}

class ListeningCompQuestionEntity extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final ListeningCompFeedbackEntity? feedback;

  const ListeningCompQuestionEntity({
    required this.id, required this.questionText, required this.options, required this.correctAnswerIndex, this.feedback,
  });

  factory ListeningCompQuestionEntity.fromJson(Map<String, dynamic> json) => ListeningCompQuestionEntity(
    id: (json['_id'] ?? json['id']).toString(),
    questionText: json['questionText'] ?? '',
    options: List<String>.from(json['options'] ?? []),
    correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
    feedback: json['feedback'] != null ? ListeningCompFeedbackEntity.fromJson(json['feedback']) : null,
  );

  @override
  List<Object?> get props => [id, questionText, options, correctAnswerIndex, feedback];
}

class ListeningCompEntity extends Equatable {
  final String id;
  final String title;
  final int totalQuestions;
  final String? summary;
  final String audioUrl;
  final String transcript;
  final String difficulty;
  final int minutesToComplete;
  final List<ListeningCompQuestionEntity> questions;
  final double userProgress;
  final int highScore;

  const ListeningCompEntity({
    required this.id, required this.title, this.summary,required this.totalQuestions, required this.audioUrl, required this.transcript,
    required this.difficulty, required this.minutesToComplete, required this.questions,
    this.userProgress = 0.0, this.highScore = 0,
  });

  factory ListeningCompEntity.fromJson(Map<String, dynamic> json) {
    // Logic: Nếu Backend trả về totalQuestions thì dùng,
    // nếu không thì mới đếm độ dài mảng questions (phòng trường hợp fetch detail)
    final questionsList = (json['questions'] as List?)?.map((e) => ListeningCompQuestionEntity.fromJson(e)).toList() ?? [];

    return ListeningCompEntity(
      id: (json['_id'] ?? json['id']).toString(),
      title: json['title'] ?? '',
      // 🔥 CẬP NHẬT TẠI ĐÂY:
      totalQuestions: json['totalQuestions'] ?? questionsList.length,

      summary: json['summary'],
      audioUrl: json['audioUrl'] ?? '',
      transcript: json['transcript'] ?? '',
      difficulty: json['difficulty'] ?? 'easy',
      minutesToComplete: json['minutesToComplete'] ?? 5,
      userProgress: (json['userProgress'] as num?)?.toDouble() ?? 0.0,
      highScore: (json['highScore'] as num?)?.toInt() ?? 0,
      questions: questionsList,
    );
  }

  @override
  List<Object?> get props => [
    id, title, totalQuestions, summary, audioUrl, transcript,
    difficulty, minutesToComplete, questions, userProgress, highScore
  ];
}

class ListeningCompAttemptResult {
  final double score;
  final int correctCount;
  final int totalQuestions;
  final List<Map<String, dynamic>> answers;

  ListeningCompAttemptResult({required this.score, required this.correctCount, required this.totalQuestions, required this.answers});

  factory ListeningCompAttemptResult.fromJson(Map<String, dynamic> json) => ListeningCompAttemptResult(
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
    correctCount: json['correctCount'] ?? 0,
    totalQuestions: json['totalQuestions'] ?? 0,
    answers: List<Map<String, dynamic>>.from(json['answers'] ?? []),
  );
}