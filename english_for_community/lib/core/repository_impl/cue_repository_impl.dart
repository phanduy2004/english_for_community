// core/repository_impl/cue_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';

import '../datasource/cue_remote_datasource.dart';
import '../entity/cue_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/cue_repository.dart';


class CueRepositoryImpl implements CueRepository {
  final CueRemoteDatasource cueRemoteDatasource;

  CueRepositoryImpl({required this.cueRemoteDatasource});

  @override
  Future<Either<Failure, List<CueEntity>>> getCuesByListeningId(
      String listeningId, {
        int from = 0,
        int limit = 200,
      }) async {
    try {
      final items = await cueRemoteDatasource.listCuesByListeningId(
        listeningId,
        from: from,
        limit: limit,
      );
      return Right(items);
    } on DioException catch (e) {
      return Left(CueFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(CueFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubmitResult>> submitCue({
    required String listeningId,
    required int cueIdx,
    required String userText,
    int? playedMs,
  }) async {
    try {
      final result = await cueRemoteDatasource.submitResult(
        listeningId: listeningId,
        cueIdx: cueIdx,
        userText: userText,
        playedMs: playedMs,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(CueFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(CueFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DictationAttemptEntity>>> listDictationAttempt(String listeningId)async {
    try {
      final result = await cueRemoteDatasource.listDictationAttempt(
        listeningId,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(CueFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(CueFailure(message: e.toString()));
    }
  }
}
