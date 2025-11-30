import 'package:equatable/equatable.dart';

// 💡 Dịch cho bài đọc chính
class TranslationEntity extends Equatable {
  final String title;
  final String content;

  const TranslationEntity({required this.title, required this.content});

  factory TranslationEntity.fromJson(Map<String, dynamic> json) {
    return TranslationEntity(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'content': content};
  @override
  List<Object?> get props => [title, content];
}

// 💡 Dịch cho câu hỏi
class QuestionTranslationEntity extends Equatable {
  final String questionText;
  final List<String> options;

  const QuestionTranslationEntity({required this.questionText, required this.options});

  factory QuestionTranslationEntity.fromJson(Map<String, dynamic> json) {
    return QuestionTranslationEntity(
      questionText: json['questionText'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((opt) => opt.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {'questionText': questionText, 'options': options};
  @override
  List<Object?> get props => [questionText, options];
}