// lib/core/datasource/cue_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';
import 'package:english_for_community/core/repository/cue_repository.dart';
import '../entity/cue_entity.dart';

class CueRemoteDatasource {
  final Dio dio;
  CueRemoteDatasource({required this.dio});

  Future<List<CueEntity>> listCuesByListeningId(
      String listeningId, {
        int from = 0,
        int limit = 200,
      }) async {
    final res = await dio.get(
      'cues',
      queryParameters: {'listeningId': listeningId, 'from': from, 'limit': limit},
    );
    final data = res.data;
    if (data is List) {
      return data.map((e) => CueEntity.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const <CueEntity>[];
  }
  Future<List<DictationAttemptEntity>> listDictationAttempt(String listeningId) async {
    final res = await dio.get(
      '/dictation/attempts', // <-- đúng path
      queryParameters: {
        'listeningId': listeningId,
        'latest': true, // lấy bản mới nhất mỗi cue
      },
      // chú ý: dio này phải là authorized = true để server đọc req.user
    );

    final body = res.data;
    final list = (body is Map<String, dynamic>) ? (body['attempts'] as List? ?? const []) : const [];
    return list
        .map((e) => DictationAttemptEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ⬇️ đổi tên + kiểu trả về
  Future<SubmitResult> submitResult({
    required String listeningId,
    required int cueIdx,
    required String userText,
    int? playedMs,
  }) async {
    final res = await dio.post('dictation/submit', data: {
      'listeningId': listeningId,
      'cueIdx': cueIdx,
      'userText': userText,
      'playedMs': playedMs,
    });

    final data = res.data as Map<String, dynamic>;
    final passed = (data['passed'] as bool?) ?? (data['message'] == 'true');

    double wer = 0, cer = 0;
    if (data['score'] is Map) {
      final s = data['score'] as Map;
      wer = (s['wer'] as num?)?.toDouble() ?? 0.0;
      cer = (s['cer'] as num?)?.toDouble() ?? 0.0;
    }

    return SubmitResult(passed: passed, wer: wer, cer: cer);
  }
}
