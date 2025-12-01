// lib/core/datasource/speaking_remote_datasource.dart
import 'package:dio/dio.dart';
import '../entity/speaking/speaking_attempt_entity.dart';
import '../entity/speaking/speaking_set_entity.dart';
import '../dtos/speaking_response_dto.dart';

class SpeakingRemoteDatasource {
  final Dio dio;
  SpeakingRemoteDatasource({required this.dio});

  /// Lấy danh sách Speaking Sets (có tiến độ) cho SpeakingHubPage
  /// API: GET /speaking/sets
  Future<PaginatedResult<SpeakingSetProgressEntity>> getSpeakingSetsWithProgress({
    required String mode,
    required String level,
    int page = 1,
    int limit = 10,
  }) async {
    final res = await dio.get(
      'speaking/sets', // API Path (từ speaking.routes.js)
      queryParameters: {
        'mode': mode,
        'level': level,
        'page': page,
        'limit': limit,
      },
    );
    final body = res.data as Map<String, dynamic>;
    // 1. Parse 'data' (List)
    final dataList = (body['data'] as List? ?? []);
    final sets = dataList
        .map((e) => SpeakingSetProgressEntity.fromJson(e as Map<String, dynamic>))
        .toList();

    // 2. Parse 'pagination' (Object)
    final paginationMap = (body['pagination'] as Map<String, dynamic>?);
    final pagination = paginationMap != null
        ? PaginationEntity.fromJson(paginationMap)
        : PaginationEntity.empty();

    return PaginatedResult(data: sets, pagination: pagination);
  }

  /// Lấy chi tiết 1 Speaking Set (kèm sentences) cho SpeakingSkillsPage
  /// API: GET /speaking/sets/:setId
  Future<SpeakingSetEntity> getSpeakingSetDetails(String setId) async {
    final res = await dio.get(
      'speaking/sets/$setId', // API Path (từ speaking.routes.js)
    );

    final data = res.data as Map<String, dynamic>;
    // Dùng .fromJson() từ file 'speaking_set_entity.dart'
    return SpeakingSetEntity.fromJson(data);
  }

  Future<SpeakingAttemptEntity> submitSpeakingAttempt({
    required String speakingSetId,
    required String sentenceId,
    required String userTranscript,
    required String userAudioUrl,
    required SpeakingScoreEntity score,
    required int audioDurationSeconds, // <-- THÊM DÒNG NÀY
  }) async {
    final res = await dio.post(
      'speaking/submit', // (Bạn cần tạo API này, nó chưa có trong controller)
      data: {
        'speakingSetId': speakingSetId,
        'sentenceId': sentenceId,
        'userTranscript': userTranscript,
        'userAudioUrl': userAudioUrl,
        'score': score.toJson(),
        'audioDurationSeconds' : audioDurationSeconds
      },
    );
    final data = res.data as Map<String, dynamic>;
    return SpeakingAttemptEntity.fromJson(data);
  }
  Future<PaginatedResult<SpeakingSetEntity>> getAdminSpeakingList({int page = 1, int limit = 20}) async {
    final res = await dio.get('speaking/admin/list', queryParameters: {'page': page, 'limit': limit});
    final body = res.data;
    final List<SpeakingSetEntity> data = (body['data'] as List).map((e) => SpeakingSetEntity.fromJson(e)).toList();
    final pagination = PaginationEntity.fromJson(body['pagination']);
    return PaginatedResult(data: data, pagination: pagination);
  }

  Future<SpeakingSetEntity> getAdminSpeakingDetail(String id) async {
    final res = await dio.get('speaking/admin/$id');
    return SpeakingSetEntity.fromJson(res.data['data']);
  }

  Future<SpeakingSetEntity> createSpeakingSet(Map<String, dynamic> payload) async {
    final res = await dio.post('speaking/admin', data: payload);
    return SpeakingSetEntity.fromJson(res.data['data']);
  }

  Future<SpeakingSetEntity> updateSpeakingSet(String id, Map<String, dynamic> payload) async {
    final res = await dio.put('speaking/admin/$id', data: payload);
    return SpeakingSetEntity.fromJson(res.data['data']);
  }

  Future<void> deleteSpeakingSet(String id) async {
    await dio.delete('speaking/admin/$id');
  }
}