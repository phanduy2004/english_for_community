// lib/core/repository_impl/reading_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';

import '../../feature/reading/reading_attempt_bloc/reading_attempt_payload.dart';
import '../datasource/reading_remote_datasource.dart';
import '../repository/reading_repository.dart';
import '../entity/reading/reading_entity.dart';
import '../entity/reading/reading_attempt_entity.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  final ReadingRemoteDatasource readingRemoteDatasource;

  ReadingRepositoryImpl({required this.readingRemoteDatasource});

  @override
  Future<Either<Failure, PaginatedResult<ReadingEntity>>> getReadingListWithProgress({
    required String difficulty,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await readingRemoteDatasource.getReadingListWithProgress(
        difficulty: difficulty,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ReadingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ReadingFailure(message: e.toString()));
    }
  }

  // 👇 3. TRIỂN KHAI HÀM LẤY CHI TIẾT
  @override
  Future<Either<Failure, ReadingEntity>> getReadingDetail(String id) async {
    try {
      final result = await readingRemoteDatasource.getReadingDetail(id);
      return Right(result);
    } on DioException catch (e) {
      return Left(ReadingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ReadingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReadingAttemptEntity>> submitReadingAttempt({
    required String readingId,
    required List<AnswerPayload> answers,
    required double score,
    required int correctCount,
    required int totalQuestions,
    required int durationInSeconds,
  }) async {
    try {
      final result = await readingRemoteDatasource.submitReadingAttempt(
        readingId: readingId,
        answers: answers,
        score: score,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        durationInSeconds: durationInSeconds,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ReadingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ReadingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReadingAttemptEntity>>> getAttemptHistory(String readingId) async {
    try {
      final result = await readingRemoteDatasource.getAttemptHistory(readingId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ReadingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ReadingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReadingEntity>> createReading(ReadingEntity reading) async {
    try {
      final body = reading.toJson();

      // Xóa ID để tránh lỗi Backend/MongoDB
      body.remove('id');
      body.remove('_id');

      if (body['questions'] != null && body['questions'] is List) {
        for (var q in body['questions']) {
          if (q is Map) {
            q.remove('_id');
            q.remove('id');
          }
        }
      }

      final result = await readingRemoteDatasource.createReading(body);
      return Right(result);
    } on DioException catch (e) {
      return Left(ReadingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ReadingFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> deleteReading(String id) async {
    try {
      await readingRemoteDatasource.deleteReading(id);
      return  Right(null);
    } on DioException catch (e) {
      return Left(ReadingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ReadingFailure(message: e.toString()));
    }
  }
}