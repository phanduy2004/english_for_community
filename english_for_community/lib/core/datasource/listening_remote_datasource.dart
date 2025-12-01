import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import '../entity/dictation_attempt_entity.dart';

class ListeningRemoteDatasource {
  final Dio dio;

  // ⚠️ Endpoint này phải khớp với route trong index.js của backend
  // Dựa vào log của bạn: http://.../api/listening/submit => endpoint là 'listening'
  final String _endpoint = 'listening';

  ListeningRemoteDatasource({required this.dio});

  // ==================================================
  // 🕒 HISTORY / ATTEMPTS (Đã sửa lại route)
  // ==================================================
  Future<List<DictationAttemptEntity>> getDictationAttempts(String listeningId) async {
    // 🟢 SỬA: Gọi vào /api/listening/attempts thay vì /api/dictation/attempts
    final res = await dio.get(
      '$_endpoint/attempts',
      queryParameters: {
        'listeningId': listeningId,
        'latest': true, // Lấy lượt làm mới nhất
      },
    );

    final data = res.data;
    if (data is List) {
      return data
          .map((e) => DictationAttemptEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ==================================================
  // 📋 GET LIST
  // ==================================================
  Future<PaginatedResult<ListeningEntity>> getListenings({
    int page = 1,
    int limit = 20,
    String? difficulty,
    String? q,
    String? lessonId,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (difficulty != null && difficulty != 'all') queryParams['difficulty'] = difficulty;
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (lessonId != null) queryParams['lessonId'] = lessonId;

    final res = await dio.get(_endpoint, queryParameters: queryParams);

    final body = res.data as Map<String, dynamic>;

    final List<ListeningEntity> items = (body['data'] as List? ?? [])
        .map((e) => ListeningEntity.fromJson(e as Map<String, dynamic>))
        .toList();

    final pagination = body['pagination'] != null
        ? PaginationEntity.fromJson(body['pagination'])
        : PaginationEntity.empty();

    return PaginatedResult(data: items, pagination: pagination);
  }

  // ==================================================
  // 🎯 GET DETAIL
  // ==================================================
  Future<ListeningEntity> getListeningById(String id) async {
    final res = await dio.get('$_endpoint/$id');
    final data = res.data['data'];
    return ListeningEntity.fromJson(data);
  }

  // ==================================================
  // 📝 SUBMIT
  // ==================================================
  Future<Map<String, dynamic>> submitAttempt({
    required String listeningId,
    required List<Map<String, dynamic>> answers,
    required int durationInSeconds,
  }) async {
    // Gọi route: POST /api/listening/submit
    final res = await dio.post(
      '$_endpoint/submit',
      data: {
        'listeningId': listeningId,
        'answers': answers,
        'durationInSeconds': durationInSeconds,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  // ==================================================
  // 🛡️ ADMIN ACTIONS
  // ==================================================

  Future<ListeningEntity> createListening(Map<String, dynamic> payload) async {
    final res = await dio.post(_endpoint, data: payload);
    final data = res.data['data'];
    return ListeningEntity.fromJson(data);
  }

  Future<ListeningEntity> updateListening(String id, Map<String, dynamic> payload) async {
    final res = await dio.put('$_endpoint/$id', data: payload);
    final data = res.data['data'];
    return ListeningEntity.fromJson(data);
  }

  Future<void> deleteListening(String id) async {
    await dio.delete('$_endpoint/$id');
  }
}