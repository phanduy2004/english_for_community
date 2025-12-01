import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/user_word_entity.dart';

// ✍️ Enum trạng thái
enum VocabularyStatus { initial, loading, success, error }

class VocabularyState extends Equatable {
  final VocabularyStatus status;
  final String? errorMessage;

  // ✍️ Dữ liệu trả về bao gồm 3 danh sách
  final List<UserWordEntity> recentWords;
  final List<UserWordEntity> learningWords;
  final List<UserWordEntity> savedWords;

  const VocabularyState({
    required this.status,
    this.errorMessage,
    this.recentWords = const [],
    this.learningWords = const [],
    this.savedWords = const [],
  });

  factory VocabularyState.initial() =>
      const VocabularyState(status: VocabularyStatus.initial);

  VocabularyState copyWith({
    VocabularyStatus? status,
    String? errorMessage,
    List<UserWordEntity>? recentWords,
    List<UserWordEntity>? learningWords,
    List<UserWordEntity>? savedWords,
  }) {
    return VocabularyState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      recentWords: recentWords ?? this.recentWords,
      learningWords: learningWords ?? this.learningWords,
      savedWords: savedWords ?? this.savedWords,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    recentWords,
    learningWords,
    savedWords,
  ];
}