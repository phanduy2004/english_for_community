import 'package:dio/dio.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../entity/listening_comp_entity.dart';

// Class gói dữ liệu phân trang (Thay thế hoàn toàn cho PaginatedResult DTO)
class ListeningCompPageData {
  final List<ListeningCompEntity> data;
  final int currentPage;
  final int totalPages;

  ListeningCompPageData({
    required this.data,
    required this.currentPage,
    required this.totalPages,
  });
}

abstract class ListeningCompRepository {
  // --- PUBLIC ROUTES ---
  Future<Either<Failure, ListeningCompPageData>> getListenings({int page = 1, int limit = 20, String? difficulty});

  Future<Either<Failure, ListeningCompEntity>> getListeningById(String id);

  Future<Either<Failure, ListeningCompAttemptResult>> submitAttempt({
    required String listeningId,
    required List<Map<String, dynamic>> answers,
    required int durationInSeconds
  });

  Future<Either<Failure, ListeningCompAttemptResult?>> getLatestAttempt(String listeningId);

  // --- ADMIN ROUTES ---
  Future<Either<Failure, void>> createListeningComp({
    required Map<String, dynamic> data,
    MultipartFile? audioFile,
  });

  Future<Either<Failure, void>> updateListeningComp({
    required String id,
    required Map<String, dynamic> data,
    MultipartFile? audioFile,
  });

  Future<Either<Failure, void>> deleteListeningComp(String id);
}