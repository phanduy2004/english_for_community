// lib/core/repository/reading_repository.dart
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';

import '../../feature/reading/reading_attempt_bloc/reading_attempt_payload.dart';
import '../entity/reading/reading_entity.dart';
import '../entity/reading/reading_attempt_entity.dart';

abstract class ReadingRepository {
  Future<Either<Failure, PaginatedResult<ReadingEntity>>> getReadingListWithProgress({
    required String difficulty,
    int page = 1,
    int limit = 10,
  });

  // 👇 2. THÊM KHAI BÁO HÀM
  Future<Either<Failure, ReadingEntity>> getReadingDetail(String id);

  Future<Either<Failure, ReadingAttemptEntity>> submitReadingAttempt({
    required String readingId,
    required List<AnswerPayload> answers,
    required double score,
    required int correctCount,
    required int totalQuestions,
    required int durationInSeconds,
  });

  Future<Either<Failure, List<ReadingAttemptEntity>>> getAttemptHistory(String readingId);
  Future<Either<Failure, void>> deleteReading(String id);
  Future<Either<Failure, ReadingEntity>> createReading(ReadingEntity reading);
}