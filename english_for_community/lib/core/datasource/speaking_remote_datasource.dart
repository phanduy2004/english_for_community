// lib/core/datasource/speaking_remote_datasource.dart
import 'package:dio/dio.dart';
import '../entity/speaking/speaking_attempt_entity.dart';
import '../entity/speaking/speaking_set_entity.dart';
import '../entity/speaking_conversation_entity.dart';
import '../entity/speaking_phase2_entity.dart';
import '../dtos/speaking_response_dto.dart';

class SpeakingRemoteDatasource {
  final Dio dio;
  SpeakingRemoteDatasource({required this.dio});

  /// Lấy danh sách Speaking Sets (có tiến độ) cho SpeakingHubPage
  /// API: GET /speaking/sets
  Future<PaginatedResult<SpeakingSetProgressEntity>>
      getSpeakingSetsWithProgress({
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
        .map((e) =>
            SpeakingSetProgressEntity.fromJson(e as Map<String, dynamic>))
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
        'audioDurationSeconds': audioDurationSeconds
      },
    );
    final data = res.data as Map<String, dynamic>;
    return SpeakingAttemptEntity.fromJson(data);
  }

  Future<SpeakingConversationEntity> evaluateConversation({
    required List<SpeakingTurnEntity> turns,
    required int durationSeconds,
    DateTime? startedAt,
    DateTime? endedAt,
    String? level,
    String? scenarioId,
  }) async {
    final res = await dio.post(
      'speaking/conversation/evaluate',
      data: {
        'turns': turns.map((turn) => turn.toJson()).toList(),
        'durationSeconds': durationSeconds,
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
        if (level != null) 'level': level,
        if (scenarioId != null && scenarioId.isNotEmpty)
          'scenarioId': scenarioId,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return SpeakingConversationEntity.fromJson(
      data['conversation'] as Map<String, dynamic>,
    );
  }

  Future<PaginatedResult<SpeakingConversationSummaryEntity>>
      getConversationHistory({
    int limit = 20,
    String? cursor,
  }) async {
    final res = await dio.get(
      'speaking/conversation/history',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List? ?? const [])
        .map((e) => SpeakingConversationSummaryEntity.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();
    final pagination = PaginationEntity.fromJson(
      (body['pagination'] as Map<String, dynamic>?) ?? const {},
    );
    return PaginatedResult(data: data, pagination: pagination);
  }

  Future<SpeakingConversationEntity> getConversationById(String id) async {
    final res = await dio.get('speaking/conversation/$id');
    final data = res.data as Map<String, dynamic>;
    return SpeakingConversationEntity.fromJson(
      data['conversation'] as Map<String, dynamic>,
    );
  }

  Future<List<SpeakingScenarioEntity>> getSpeakingScenarios({
    String? group,
    String? level,
  }) async {
    final res = await dio.get(
      'speaking/scenarios',
      queryParameters: {
        if (group != null) 'group': group,
        if (level != null) 'level': level,
      },
    );
    final body = res.data as Map<String, dynamic>;
    return (body['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) =>
            SpeakingScenarioEntity.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SpeakingProgressSummaryEntity> getSpeakingProgressSummary({
    String range = 'week',
  }) async {
    final res = await dio.get(
      'speaking/progress/summary',
      queryParameters: {'range': range},
    );
    return SpeakingProgressSummaryEntity.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  Future<SpeakingNotebookEntity> getSpeakingNotebook({int limit = 40}) async {
    final res = await dio.get(
      'speaking/notebook',
      queryParameters: {'limit': limit},
    );
    return SpeakingNotebookEntity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaginatedResult<SpeakingSetEntity>> getAdminSpeakingList(
      {int page = 1, int limit = 20}) async {
    final res = await dio.get('speaking/admin/list',
        queryParameters: {'page': page, 'limit': limit});
    final body = res.data;
    final List<SpeakingSetEntity> data = (body['data'] as List)
        .map((e) => SpeakingSetEntity.fromJson(e))
        .toList();
    final pagination = PaginationEntity.fromJson(body['pagination']);
    return PaginatedResult(data: data, pagination: pagination);
  }

  Future<SpeakingSetEntity> getAdminSpeakingDetail(String id) async {
    final res = await dio.get('speaking/admin/$id');
    return SpeakingSetEntity.fromJson(res.data['data']);
  }

  Future<SpeakingSetEntity> createSpeakingSet(
      Map<String, dynamic> payload) async {
    final res = await dio.post('speaking/admin', data: payload);
    return SpeakingSetEntity.fromJson(res.data['data']);
  }

  Future<SpeakingSetEntity> updateSpeakingSet(
      String id, Map<String, dynamic> payload) async {
    final res = await dio.put('speaking/admin/$id', data: payload);
    return SpeakingSetEntity.fromJson(res.data['data']);
  }

  Future<void> deleteSpeakingSet(String id) async {
    await dio.delete('speaking/admin/$id');
  }
}
