import 'package:equatable/equatable.dart';

import '../../../core/entity/user_word_entity.dart';

// ✍️ Class cha trừu tượng
abstract class VocabularyEvent extends Equatable {
  const VocabularyEvent();

  @override
  List<Object> get props => [];
}

/// Sự kiện được gọi khi trang Vocabulary tải lần đầu
/// hoặc khi người dùng kéo để làm mới (pull-to-refresh)
class FetchVocabularyData extends VocabularyEvent {
  const FetchVocabularyData();
}
class StartLearningWordEvent extends VocabularyEvent {
  final UserWordEntity userWord;

  const StartLearningWordEvent(this.userWord);

  @override
  List<Object> get props => [userWord];
}

