// lib/core/repository_impl/speaking_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/speaking_remote_datasource.dart';
import 'package:english_for_community/core/repository/speaking_repository.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/entity/speaking/speaking_attempt_entity.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import 'package:english_for_community/feature/speaking/speaking_hub_page.dart';

class SpeakingRepositoryImpl implements SpeakingRepository {
  final SpeakingRemoteDatasource speakingRemoteDatasource;

  SpeakingRepositoryImpl({required this.speakingRemoteDatasource});

  @override
  Future<Either<Failure, PaginatedResult<SpeakingSetProgressEntity>>> getSpeakingSets({
    required SpeakingMode mode,
    required String level,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await speakingRemoteDatasource.getSpeakingSetsWithProgress(
        mode: mode.name,
        level: level,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(SpeakingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SpeakingSetEntity>> getSpeakingSetDetails(String setId) async {
    try {
      final result = await speakingRemoteDatasource.getSpeakingSetDetails(setId);
      return Right(result);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(SpeakingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SpeakingAttemptEntity>> submitSpeakingAttempt({
    required String speakingSetId,
    required String sentenceId,
    required String userTranscript,
    required String userAudioUrl,
    required SpeakingScoreEntity score,
    required int audioDurationSeconds, // <-- THÊM DÒNG NÀY
  }) async {
    try {
      final result = await speakingRemoteDatasource.submitSpeakingAttempt(
        speakingSetId: speakingSetId,
        sentenceId: sentenceId,
        userTranscript: userTranscript,
        userAudioUrl: userAudioUrl,
        score: score,
        audioDurationSeconds: audioDurationSeconds, // <-- GỬI LÊN BLOC
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(SpeakingFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, PaginatedResult<SpeakingSetEntity>>> getAdminSpeakingList({int page = 1, int limit = 20}) async {
    try {
      final result = await speakingRemoteDatasource.getAdminSpeakingList(page: page, limit: limit);
      return Right(result);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(SpeakingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SpeakingSetEntity>> getAdminSpeakingDetail(String id) async {
    try {
      final result = await speakingRemoteDatasource.getAdminSpeakingDetail(id);
      return Right(result);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    }
  }

  @override
  Future<Either<Failure, SpeakingSetEntity>> createSpeakingSet(SpeakingSetEntity speakingSet) async {
    try {
      final body = _convertEntityToJson(speakingSet);
      final result = await speakingRemoteDatasource.createSpeakingSet(body);
      return Right(result);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    }
  }

  @override
  Future<Either<Failure, SpeakingSetEntity>> updateSpeakingSet(String id, SpeakingSetEntity speakingSet) async {
    try {
      final body = _convertEntityToJson(speakingSet);
      final result = await speakingRemoteDatasource.updateSpeakingSet(id, body);
      return Right(result);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSpeakingSet(String id) async {
    try {
      await speakingRemoteDatasource.deleteSpeakingSet(id);
      return  Right(null);
    } on DioException catch (e) {
      return Left(SpeakingFailure(message: e.response?.data['message'] ?? e.message));
    }
  }

  Map<String, dynamic> _convertEntityToJson(SpeakingSetEntity entity) {
    final body = entity.toJson();
    // Xóa ID của SpeakingSet để Backend tự xử lý (nếu create) hoặc lấy từ URL (nếu update)
    body.remove('id');
    body.remove('_id');

    // Clean Sentences IDs
    if (body['sentences'] != null && body['sentences'] is List) {
      final list = body['sentences'] as List;
      body['sentences'] = list.map((s) {
        if (s is Map) {
          final map = Map<String, dynamic>.from(s);
          // Xóa ID nếu nó là ID tạm hoặc rỗng
          if (map['id'] == null || map['id'].toString().isEmpty) {
            map.remove('id');
          }
          // Backend Mongoose sub-doc không dùng _id mặc định nếu config { _id: false }
          // Nhưng cứ xóa cho an toàn
          map.remove('_id');
          return map;
        }
        return s;
      }).toList();
    }
    return body;
  }
}