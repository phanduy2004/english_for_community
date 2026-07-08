// lib/core/datasource/reading_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../feature/reading/reading_attempt_bloc/reading_attempt_payload.dart';
import '../dtos/speaking_response_dto.dart';
import '../entity/reading/reading_entity.dart';
import '../entity/reading/reading_attempt_entity.dart';

class ReadingRemoteDatasource {
  final Dio dio;
  ReadingRemoteDatasource({required this.dio});

  Future<PaginatedResult<ReadingEntity>> getReadingListWithProgress({
    required String difficulty,
    int page = 1,
    int limit = 10,
  }) async {
    final res = await dio.get(
      'reading',
      queryParameters: {
        'difficulty': difficulty,
        'page': page,
        'limit': limit,
      },
    );
    final body = res.data as Map<String, dynamic>;

    final dataList = (body['data'] as List? ?? []);
    final readings = dataList
        .map((e) => ReadingEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    final paginationMap = (body['pagination'] as Map<String, dynamic>?);
    final pagination = paginationMap != null
        ? PaginationEntity.fromJson(paginationMap)
        : PaginationEntity.empty();

    return PaginatedResult(data: readings, pagination: pagination);
  }

  // 👇 1. THÊM HÀM LẤY CHI TIẾT
  Future<ReadingEntity> getReadingDetail(String id) async {
    final res = await dio.get('reading/$id');

    // Backend trả về { "data": { ... } }
    final responseData = res.data['data'] ?? res.data;

    return ReadingEntity.fromJson(responseData as Map<String, dynamic>);
  }

  Future<ReadingEntity> createReading(Map<String, dynamic> body) async {
    final res = await dio.post(
      'reading',
      data: body,
    );
    final responseData = res.data['data'] ?? res.data;
    return ReadingEntity.fromJson(responseData as Map<String, dynamic>);
  }

  Future<ReadingEntity> updateReading(String id, Map<String, dynamic> body) async {
    final res = await dio.put(
      'reading/$id',
      data: body,
    );
    final responseData = res.data['data'] ?? res.data;
    return ReadingEntity.fromJson(responseData as Map<String, dynamic>);
  }

  Future<ReadingAttemptEntity> submitReadingAttempt({
    required String readingId,
    required List<AnswerPayload> answers,
    required double score,
    required int correctCount,
    required int totalQuestions,
    required int durationInSeconds,
  }) async {
    final res = await dio.post(
      'reading/submit',
      data: {
        'readingId': readingId,
        'answers': answers.map((a) => a.toJson()).toList(),
        'score': score,
        'correctCount': correctCount,
        'totalQuestions': totalQuestions,
        'durationInSeconds': durationInSeconds,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return ReadingAttemptEntity.fromJson(data);
  }

  Future<List<ReadingAttemptEntity>> getAttemptHistory(String readingId) async {
    final res = await dio.get(
      'reading/history/$readingId',
    );
    final dataList = res.data as List<dynamic>? ?? [];
    final history = dataList
        .map((e) => ReadingAttemptEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    return history;
  }
  Future<void> deleteReading(String id) async {
    await dio.delete('reading/$id');
    // Nếu backend trả về success 200 là ok, không cần return dữ liệu
  }
}