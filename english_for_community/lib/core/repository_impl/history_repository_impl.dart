import '../../feature/admin/submission_managerment/model/activity_model.dart';

import '../datasource/history_remote_datasource.dart';
import '../entity/dictation_attempt_entity.dart';
import '../entity/reading/reading_attempt_entity.dart';
import '../entity/speaking/sentence_entity.dart';
import '../entity/speaking/speaking_attempt_entity.dart';
import '../entity/speaking/speaking_set_entity.dart';
import '../entity/writing_submission_entity.dart';
// 🔥 IMPORT THÊM ENTITY CỦA COMPREHENSION
import '../entity/listening_comp_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDatasource historyRemoteDatasource;

  HistoryRepositoryImpl({required this.historyRemoteDatasource});

  @override
  Future<Either<Failure, List<ActivityModel>>> getHistory({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    try {
      final result = await historyRemoteDatasource.getHistory(
        startDate: start,
        endDate: end,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  // 🔥 THÊM THAM SỐ {String? subType} VÀO ĐÂY
  Future<Either<Failure, dynamic>> getActivityDetail(String id, ActivityType type, {String? subType}) async {
    try {
      // Truyền thêm subType xuống Datasource
      final json = await historyRemoteDatasource.getActivityDetail(id, type.name, subType: subType);

      // 🔥 MAP DỮ LIỆU TƯƠNG ỨNG TỪNG LOẠI
      switch (type) {
        case ActivityType.writing:
          return Right(WritingSubmissionEntity.fromJson(json));

        case ActivityType.reading:
          return Right(ReadingAttemptEntity.fromJson(json));

        case ActivityType.speaking:
          final List<dynamic> rawSentences = json['sentences'] ?? [];

          final sentencesEntity = rawSentences.map((s) {
            final List<dynamic> rawHistory = s['history'] ?? [];

            final historyEntities = rawHistory.map((h) {
              return SpeakingAttemptEntity(
                id: h['_id'] ?? '',
                sentenceId: h['sentenceId'] ?? s['id'] ?? '',
                userTranscript: h['userTranscript'],
                userAudioUrl: h['userAudioUrl'],
                audioDurationSeconds: (h['audioDurationSeconds'] as num?)?.toInt(),
                score: h['score'] != null
                    ? SpeakingScoreEntity.fromJson(h['score'])
                    : const SpeakingScoreEntity(wer: 1.0, confidence: 0.0),
                submittedAt: DateTime.tryParse(h['submittedAt'] ?? ''),
              );
            }).toList();

            return SentenceEntity(
              id: s['id'] ?? '',
              order: (s['order'] as num?)?.toInt() ?? 0,
              speaker: s['speaker'] ?? '',
              script: s['script'] ?? '',
              phoneticScript: s['phonetic_script'] ?? '',
              history: historyEntities,
            );
          }).toList();

          return Right(SpeakingSetEntity(
            id: json['_id'] ?? '',
            title: json['title'] ?? 'Speaking Detail',
            description: json['description'] ?? '',
            level: json['level'] ?? 'Beginner',
            mode: json['mode'] ?? 'readAloud',
            sentences: sentencesEntity,
            totalSentences: sentencesEntity.length,
          ));

        case ActivityType.listening:
        // 🔥 RẼ NHÁNH XỬ LÝ COMPREHENSION VÀ DICTATION
          if (subType == 'Comprehension') {
            // Parse dữ liệu Comprehension
            final attempt = ListeningCompAttemptResult.fromJson(json);

            // Backend trả đề bài gốc ở field listeningId
            final detail = ListeningCompEntity.fromJson(json['listeningId']);

            // Trả về một Map chứa cả 2 để BLoC lấy
            return Right({
              'attempt': attempt,
              'detail': detail,
            });
          } else {
            // Parse Dictation (Giữ nguyên logic cũ của bạn)
            final List<dynamic> attemptsJson = json['attemptsDetail'] ?? [];
            final attempts = attemptsJson.map((e) => DictationAttemptEntity.fromJson(e)).toList();
            return Right(attempts);
          }

        default:
          return Left(ServerFailure(message: "Unsupported type"));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}