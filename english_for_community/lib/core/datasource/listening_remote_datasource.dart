import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:english_for_community/core/dtos/speaking_response_dto.dart';
import 'package:flutter/foundation.dart';
import '../entity/comment_entity.dart';
import '../entity/dictation_attempt_entity.dart';
import 'package:file_picker/file_picker.dart';

class ListeningRemoteDatasource {
  final Dio dio;
  final String _endpoint = 'listening'; // Khớp với backend router

  ListeningRemoteDatasource({required this.dio});

  // --- Attempts & History ---
  Future<List<DictationAttemptEntity>> getDictationAttempts(String listeningId) async {
    final res = await dio.get('$_endpoint/attempts', queryParameters: {
      'listeningId': listeningId,
      'latest': true,
    });
    return (res.data as List).map((e) => DictationAttemptEntity.fromJson(e)).toList();
  }

  // --- Get List ---
  Future<PaginatedResult<ListeningEntity>> getListenings({
    int page = 1, int limit = 20, String? difficulty, String? q, String? lessonId,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (difficulty != null) query['difficulty'] = difficulty;
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (lessonId != null) query['lessonId'] = lessonId;

    final res = await dio.get(_endpoint, queryParameters: query);
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List? ?? []).map((e) => ListeningEntity.fromJson(e)).toList();
    final pag = body['pagination'] != null ? PaginationEntity.fromJson(body['pagination']) : PaginationEntity.empty();
    return PaginatedResult(data: items, pagination: pag);
  }

  // --- Get Detail ---
  Future<ListeningEntity> getListeningById(String id) async {
    final res = await dio.get('$_endpoint/$id');
    return ListeningEntity.fromJson(res.data['data']);
  }

  // --- Submit ---
  Future<Map<String, dynamic>> submitAttempt({
    required String listeningId,
    required List<Map<String, dynamic>> answers,
    required int durationInSeconds,
  }) async {
    final res = await dio.post('$_endpoint/submit', data: {
      'listeningId': listeningId,
      'answers': answers,
      'durationInSeconds': durationInSeconds,
    });
    return res.data;
  }

  // --- Comments ---
  Future<Map<String, dynamic>> getCueComments(String listeningId, String cueId, int page) async {
    final res = await dio.get('$_endpoint/$listeningId/cues/$cueId/comments', queryParameters: {'page': page, 'limit': 20});
    return res.data;
  }

  Future<CommentEntity> postComment({
    required String listeningId,
    required String cueId,
    required String content,
    String? parentId,
  }) async {
    final res = await dio.post('$_endpoint/comments', data: {
      'listeningId': listeningId,
      'cueId': cueId,
      'content': content,
      'parentId': parentId,
    });
    return CommentEntity.fromJson(res.data);
  }

  Future<void> reactToComment({required String commentId, required String type}) async {
    await dio.post('$_endpoint/comments/$commentId/react', data: {'type': type});
  }

  // --- Admin ---
  Future<ListeningEntity> createListening(Map<String, dynamic> payload, PlatformFile? audioFile) async {
    final formData = _createFormData(payload, audioFile);
    final res = await dio.post(_endpoint, data: formData);
    return ListeningEntity.fromJson(res.data['data']);
  }

  Future<ListeningEntity> updateListening(String id, Map<String, dynamic> payload, PlatformFile? audioFile) async {
    final formData = _createFormData(payload, audioFile);
    final res = await dio.put('$_endpoint/$id', data: formData);
    return ListeningEntity.fromJson(res.data['data']);
  }

  Future<void> deleteListening(String id) async {
    await dio.delete('$_endpoint/$id');
  }

  FormData _createFormData(Map<String, dynamic> payload, PlatformFile? audioFile) {
    final formData = FormData.fromMap({
      'title': payload['title'],
      'code': payload['code'],
      'cefr': payload['cefr'],
      'difficulty': payload['difficulty'],
      'cues': jsonEncode(payload['cues']),
    });

    if (audioFile != null) {
      if (kIsWeb) {
        formData.files.add(MapEntry('audio', MultipartFile.fromBytes(audioFile.bytes!, filename: audioFile.name)));
      } else if (audioFile.path != null) {
        formData.files.add(MapEntry('audio', MultipartFile.fromFileSync(audioFile.path!, filename: audioFile.name)));
      }
    }
    return formData;
  }
}