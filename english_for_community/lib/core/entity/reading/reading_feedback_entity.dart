import 'package:equatable/equatable.dart';

class ReadingFeedbackEntity extends Equatable {
  final String reasoning;
  final int? paragraphIndex;
  final String? keySentence;

  const ReadingFeedbackEntity({
    required this.reasoning,
    this.paragraphIndex,
    this.keySentence,
  });

  factory ReadingFeedbackEntity.fromJson(Map<String, dynamic> json) {
    return ReadingFeedbackEntity(
      reasoning: (json['reasoning'] ?? 'No explanation provided.') as String,
      paragraphIndex: (json['paragraphIndex'] as num?)?.toInt(),
      keySentence: json['keySentence'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'reasoning': reasoning,
    'paragraphIndex': paragraphIndex,
    'keySentence': keySentence,
  };

  @override
  List<Object?> get props => [reasoning, paragraphIndex, keySentence];
}