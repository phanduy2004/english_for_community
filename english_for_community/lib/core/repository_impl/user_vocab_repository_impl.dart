import 'package:dio/dio.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/model/either.dart';
import '../datasource/user_vocab_remote_datasource.dart';
import '../entity/user_word_entity.dart';
import '../repository/user_vocab_repository.dart';
import '../sqflite/dict_db.dart';

class UserVocabRepositoryImpl implements UserVocabRepository {
  final UserVocabRemoteDatasource userVocabRemoteDatasource;

  UserVocabRepositoryImpl({required this.userVocabRemoteDatasource});

  @override
  Future<Either<Failure, List<UserWordEntity>>> getRecentWords() async {
    try {
      final words = await userVocabRemoteDatasource.getRecentWords();
      return Right(words);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserWordEntity>>> getLearningWords() async {
    try {
      final words = await userVocabRemoteDatasource.getLearningWords();
      return Right(words);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startLearningFromUserWord(UserWordEntity userWord) async {
    try {
      await userVocabRemoteDatasource.startLearningFromUserWord(userWord);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi Server/Mạng: ${e.message}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserWordEntity>>> getSavedWords() async {
    try {
      final words = await userVocabRemoteDatasource.getSavedWords();
      return Right(words);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserWordEntity>>> getWordsToReview() async {
    try {
      final words = await userVocabRemoteDatasource.getWordsToReview();
      return Right(words);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveWord(Entry entry) async {
    try {
      await userVocabRemoteDatasource.saveWord(entry);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startLearningWord(Entry entry) async {
    try {
      await userVocabRemoteDatasource.startLearningWord(entry);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logRecentWord(Entry entry) async {
    try {
      await userVocabRemoteDatasource.logRecentWord(entry);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitReviewFeedback(String wordId, String feedback, int duration) async {
    try {
      await userVocabRemoteDatasource.submitReviewFeedback(wordId, feedback, duration);
      return Right(null);
    } on DioException catch (e) {
      return Left(UserVocabFailure(message: 'Lỗi Server/Mạng: ${e.message}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, List<UserWordEntity>>> getDailyReminders() async {
    try {
      final words = await userVocabRemoteDatasource.getDailyReminders();
      return Right(words);
    } on DioException catch (e) {
      // Xử lý lỗi mạng
      return Left(UserVocabFailure(message: 'Lỗi lấy từ nhắc nhở: ${e.message}'));
    } catch (e) {
      return Left(UserVocabFailure(message: e.toString()));
    }
  }
}