
import 'package:english_for_community/core/dtos/speaking_response_dto.dart'; // Import PaginatedResult
import '../entity/dictation_attempt_entity.dart';
import '../entity/listening_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';
import 'package:file_picker/file_picker.dart'; // 🔥 Import này
abstract class ListeningRepository {
  // ==================== READ ====================

  /// Lấy danh sách bài nghe (Hỗ trợ cả Client filter & Admin pagination)
  Future<Either<Failure, PaginatedResult<ListeningEntity>>> getListenings({
    int page = 1,
    int limit = 20,
    String? difficulty,
    String? q,
    String? lessonId,
  });

  /// Lấy chi tiết bài nghe (Bao gồm cả Cues)
  Future<Either<Failure, ListeningEntity>> getListeningById(String id);

  // ==================== INTERACTION ====================

  /// Nộp bài làm (Thay thế cho CueRepository cũ)
  Future<Either<Failure, Map<String, dynamic>>> submitAttempt({
    required String listeningId,
    required List<Map<String, dynamic>> answers,
    required int durationInSeconds,
  });

  // ==================== ADMIN WRITE ====================

  Future<Either<Failure, ListeningEntity>> createListening(ListeningEntity listening, {PlatformFile? audioFile});
  Future<Either<Failure, ListeningEntity>> updateListening(String id, ListeningEntity listening, {PlatformFile? audioFile});
  Future<Either<Failure, void>> deleteListening(String id);
  Future<Either<Failure, List<DictationAttemptEntity>>> getDictationAttempts(String listeningId);
}