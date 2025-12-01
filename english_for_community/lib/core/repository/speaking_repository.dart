// lib/core/repository/speaking_repository.dart
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import 'package:english_for_community/feature/speaking/speaking_hub_page.dart';
import '../entity/speaking/speaking_attempt_entity.dart';
import '../entity/speaking/speaking_set_entity.dart';
abstract class SpeakingRepository {
  Future<Either<Failure, PaginatedResult<SpeakingSetProgressEntity>>> getSpeakingSets({
    required SpeakingMode mode,
    required String level,
    int page = 1,
    int limit = 10,
  });
  Future<Either<Failure, SpeakingSetEntity>> getSpeakingSetDetails(String setId);
  Future<Either<Failure, SpeakingAttemptEntity>> submitSpeakingAttempt({
    required String speakingSetId,
    required String sentenceId,
    required String userTranscript,
    required String userAudioUrl,
    required SpeakingScoreEntity score,
    required int audioDurationSeconds, // <-- THÊM DÒNG NÀY
  });
  Future<Either<Failure, PaginatedResult<SpeakingSetEntity>>> getAdminSpeakingList({int page, int limit});

  // Admin Detail
  Future<Either<Failure, SpeakingSetEntity>> getAdminSpeakingDetail(String id);

  // Admin Create
  Future<Either<Failure, SpeakingSetEntity>> createSpeakingSet(SpeakingSetEntity speakingSet);

  // Admin Update
  Future<Either<Failure, SpeakingSetEntity>> updateSpeakingSet(String id, SpeakingSetEntity speakingSet);

  // Admin Delete
  Future<Either<Failure, void>> deleteSpeakingSet(String id);
}