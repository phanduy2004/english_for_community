import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/entity/user_word_entity.dart';
import '../sqflite/dict_db.dart';

abstract class UserVocabRepository {
  Future<Either<Failure, List<UserWordEntity>>> getRecentWords();

  Future<Either<Failure, List<UserWordEntity>>> getLearningWords();

  Future<Either<Failure, List<UserWordEntity>>> getSavedWords();

  Future<Either<Failure, List<UserWordEntity>>> getWordsToReview();

  Future<Either<Failure, void>> startLearningWord(Entry entry);

  Future<Either<Failure, void>> saveWord(Entry entry);

  Future<Either<Failure, void>> logRecentWord(Entry entry);

  Future<Either<Failure, void>> startLearningFromUserWord(UserWordEntity userWord);

  Future<Either<Failure, void>> submitReviewFeedback(String wordId, String feedback, int duration);
  Future<Either<Failure, List<UserWordEntity>>> getDailyReminders();
}