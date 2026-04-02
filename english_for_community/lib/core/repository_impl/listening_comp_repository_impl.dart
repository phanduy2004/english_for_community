import 'package:dio/dio.dart';
import '../datasource/listening_comp_remote_datasource.dart';
import '../entity/listening_comp_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/listening_comp_repository.dart';

class ListeningCompRepositoryImpl implements ListeningCompRepository {
  final ListeningCompRemoteDatasource datasource;

  ListeningCompRepositoryImpl({required this.datasource});

  // ============================================================
  // PUBLIC ROUTES
  // ============================================================

  @override
  Future<Either<Failure, ListeningCompPageData>> getListenings({int page = 1, int limit = 20, String? difficulty}) async {
    try {
      final result = await datasource.getListenings(page: page, limit: limit, difficulty: difficulty);

      final List items = result['data'] ?? [];
      final List<ListeningCompEntity> data = items.map((e) => ListeningCompEntity.fromJson(e)).toList();

      final pagination = result['pagination'] ?? {};
      final int currentPage = pagination['page'] ?? 1;
      final int totalPages = pagination['totalPages'] ?? 1;

      return Right(ListeningCompPageData(data: data, currentPage: currentPage, totalPages: totalPages));
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListeningCompEntity>> getListeningById(String id) async {
    try {
      final result = await datasource.getListeningById(id);
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListeningCompAttemptResult>> submitAttempt({
    required String listeningId,
    required List<Map<String, dynamic>> answers,
    required int durationInSeconds
  }) async {
    try {
      final result = await datasource.submitAttempt(listeningId: listeningId, answers: answers, durationInSeconds: durationInSeconds);
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListeningCompAttemptResult?>> getLatestAttempt(String listeningId) async {
    try {
      final result = await datasource.getLatestAttempt(listeningId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  // ============================================================
  // ADMIN ROUTES
  // ============================================================

  @override
  Future<Either<Failure, void>> createListeningComp({
    required Map<String, dynamic> data,
    MultipartFile? audioFile,
  }) async {
    try {
      await datasource.createListeningComp(data: data, audioFile: audioFile);
      // Trả về Right(null) vì hàm này không cần data trả về, chỉ cần thành công
      return Right(null);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateListeningComp({
    required String id,
    required Map<String, dynamic> data,
    MultipartFile? audioFile,
  }) async {
    try {
      await datasource.updateListeningComp(id: id, data: data, audioFile: audioFile);
      return Right(null);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteListeningComp(String id) async {
    try {
      await datasource.deleteListeningComp(id);
      return Right(null);
    } on DioException catch (e) {
      return Left(ListeningFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ListeningFailure(message: e.toString()));
    }
  }
}