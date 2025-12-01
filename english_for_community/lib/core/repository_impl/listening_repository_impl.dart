import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/listening_remote_datasource.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/listening_repository.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import '../entity/dictation_attempt_entity.dart';

class ListeningRepositoryImpl implements ListeningRepository {
  final ListeningRemoteDatasource listeningRemoteDatasource;

  ListeningRepositoryImpl({required this.listeningRemoteDatasource});

  // ==================== READ IMPL ====================

  @override
  Future<Either<Failure, PaginatedResult<ListeningEntity>>> getListenings({
    int page = 1,
    int limit = 20,
    String? difficulty,
    String? q,
    String? lessonId,
  }) async {
    try {
      final result = await listeningRemoteDatasource.getListenings(
        page: page,
        limit: limit,
        difficulty: difficulty,
        q: q,
        lessonId: lessonId,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListeningEntity>> getListeningById(String id) async {
    try {
      final result = await listeningRemoteDatasource.getListeningById(id);
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DictationAttemptEntity>>> getDictationAttempts(String listeningId) async {
    try {
      final result = await listeningRemoteDatasource.getDictationAttempts(listeningId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  // ==================== INTERACTION IMPL ====================

  @override
  Future<Either<Failure, Map<String, dynamic>>> submitAttempt({
    required String listeningId,
    required List<Map<String, dynamic>> answers,
    required int durationInSeconds,
  }) async {
    try {
      final result = await listeningRemoteDatasource.submitAttempt(
        listeningId: listeningId,
        answers: answers,
        durationInSeconds: durationInSeconds,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  // ==================== ADMIN WRITE IMPL ====================

  @override
  Future<Either<Failure, ListeningEntity>> createListening(ListeningEntity listening) async {
    try {
      final body = _prepareBody(listening);
      final result = await listeningRemoteDatasource.createListening(body);
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListeningEntity>> updateListening(String id, ListeningEntity listening) async {
    try {
      final body = _prepareBody(listening);
      final result = await listeningRemoteDatasource.updateListening(id, body);
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteListening(String id) async {
    try {
      await listeningRemoteDatasource.deleteListening(id);
      return Right(null);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  // ==================== HELPER ====================

  Map<String, dynamic> _prepareBody(ListeningEntity listening) {
    final body = listening.toJson();
    body.remove('id');
    body.remove('_id');

    if (body['lessonId'] == null || body['lessonId'] == '') {
      body['lessonId'] = null;
    } else if (body['lessonId'] is Map) {
      body['lessonId'] = (body['lessonId'] as Map)['id'];
    }

    if (body['cues'] != null && body['cues'] is List) {
      final cuesList = body['cues'] as List;
      final cleanedCues = cuesList.map((cue) {
        if (cue is Map) {
          final Map<String, dynamic> cueMap = Map<String, dynamic>.from(cue);
          cueMap.remove('id');
          cueMap.remove('_id');
          return cueMap;
        }
        return cue;
      }).toList();
      body['cues'] = cleanedCues;
    }
    return body;
  }
}