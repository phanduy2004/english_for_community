
import '../../feature/admin/submission_managerment/model/activity_model.dart';

import '../datasource/history_remote_datasource.dart';
import '../entity/dictation_attempt_entity.dart';
import '../entity/reading/reading_attempt_entity.dart';
import '../entity/speaking/sentence_entity.dart';
import '../entity/speaking/speaking_attempt_entity.dart';
import '../entity/speaking/speaking_set_entity.dart';
import '../entity/writing_submission_entity.dart';
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
    String? userId, // 🔥 Tham số này phải khớp hoàn toàn với abstract
  }) async {
    try {
      final result = await historyRemoteDatasource.getHistory(
        startDate: start,
        endDate: end,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      // Xử lý lỗi (ví dụ ServerFailure)
      return Left(ServerFailure(message: e.toString()));
    }
  }
  @override
  // Return type là dynamic để trả về các Entity khác nhau tùy type
  Future<Either<Failure, dynamic>> getActivityDetail(String id, ActivityType type) async {
    try {
      final json = await historyRemoteDatasource.getActivityDetail(id, type.name);

      // 🔥 MAP DỮ LIỆU TƯƠNG ỨNG TỪNG LOẠI
      switch (type) {
        case ActivityType.writing:
          return Right(WritingSubmissionEntity.fromJson(json));

        case ActivityType.reading:
        // Sử dụng fromJson để tự động parse readingDetail và answers
          return Right(ReadingAttemptEntity.fromJson(json));
        case ActivityType.speaking:
        // 🔥 QUAN TRỌNG: Map JSON phẳng từ Admin thành SpeakingSetEntity lồng nhau
        // Backend trả về: { sentences: [{ sentenceId, script, userAudio, ... }] }
          final List<dynamic> rawSentences = json['sentences'] ?? [];

          final sentencesEntity = rawSentences.map((s) {
            // Map lịch sử (attempts) của từng câu
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
              phoneticScript: s['phonetic_script'] ?? '', // 🔥 Chú ý key này khớp JSON
              history: historyEntities,
            );
          }).toList();

          // 2. Tạo SpeakingSetEntity
          return Right(SpeakingSetEntity(
            id: json['_id'] ?? '',
            title: json['title'] ?? 'Speaking Detail',
            description: json['description'] ?? '',
            level: json['level'] ?? 'Beginner', // Giá trị mặc định nếu null
            mode: json['mode'] ?? 'readAloud',
            sentences: sentencesEntity,
            totalSentences: sentencesEntity.length,
          ));

        case ActivityType.listening:
        // Backend listening trả về object enrollment có field 'attemptsDetail'
          final List<dynamic> attemptsJson = json['attemptsDetail'] ?? [];
          final attempts = attemptsJson.map((e) => DictationAttemptEntity.fromJson(e)).toList();
          return Right(attempts);

        default:
          return Left(ServerFailure(message: "Unsupported type"));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}