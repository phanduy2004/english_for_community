import 'dart:convert';
import 'package:dio/dio.dart';
import '../entity/listening_comp_entity.dart';

class ListeningCompRemoteDatasource {
  final Dio dio;
  final String _endpoint = '/listening-comp'; // Đảm bảo khớp với base route trên Express

  ListeningCompRemoteDatasource({required this.dio});

  // ============================================================
  // 🌍 PUBLIC ROUTES (Dành cho app Flutter)
  // ============================================================

  // 1. Lấy danh sách (có phân trang, filter)
  Future<Map<String, dynamic>> getListenings({int page = 1, int limit = 20, String? difficulty}) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (difficulty != null) query['difficulty'] = difficulty;

    final res = await dio.get(_endpoint, queryParameters: query);
    return res.data;
  }

  // 2. Lấy chi tiết bài nghe
  Future<ListeningCompEntity> getListeningById(String id) async {
    final res = await dio.get('$_endpoint/$id');
    return ListeningCompEntity.fromJson(res.data['data']);
  }

  // 3. Nộp bài
  Future<ListeningCompAttemptResult> submitAttempt({
    required String listeningId,
    required List<Map<String, dynamic>> answers,
    required int durationInSeconds,
  }) async {
    final res = await dio.post('$_endpoint/submit', data: {
      'listeningId': listeningId,
      'answers': answers,
      'durationInSeconds': durationInSeconds,
    });
    return ListeningCompAttemptResult.fromJson(res.data['data']);
  }

  // 4. Lấy lịch sử làm bài (Lần gần nhất)
  Future<ListeningCompAttemptResult?> getLatestAttempt(String listeningId) async {
    final res = await dio.get('$_endpoint/attempts', queryParameters: {'listeningId': listeningId});
    final List data = res.data['data'] ?? [];
    if (data.isNotEmpty) return ListeningCompAttemptResult.fromJson(data.first);
    return null;
  }

  // ============================================================
  // 🔐 ADMIN ROUTES (Dành cho CMS/Web Admin)
  // ============================================================

  // 5. Tạo bài nghe mới (Cần FormData để upload Audio)
  Future<void> createListeningComp({
    required Map<String, dynamic> data, // Chứa title, difficulty, questions...
    MultipartFile? audioFile,
  }) async {
    // Xử lý các object phức tạp (như mảng questions) thành chuỗi JSON
    // vì form-data chỉ nhận String hoặc File
    Map<String, dynamic> stringifiedData = {};
    data.forEach((key, value) {
      if (value is List || value is Map) {
        stringifiedData[key] = jsonEncode(value);
      } else {
        stringifiedData[key] = value;
      }
    });

    final formData = FormData.fromMap(stringifiedData);

    // Nếu có file audio được chọn thì đính kèm vào key 'audio'
    if (audioFile != null) {
      formData.files.add(MapEntry('audio', audioFile));
    }

    await dio.post(_endpoint, data: formData);
  }

  // 6. Cập nhật bài nghe (Cần FormData để upload Audio)
  Future<void> updateListeningComp({
    required String id,
    required Map<String, dynamic> data,
    MultipartFile? audioFile,
  }) async {
    Map<String, dynamic> stringifiedData = {};
    data.forEach((key, value) {
      if (value is List || value is Map) {
        stringifiedData[key] = jsonEncode(value);
      } else {
        stringifiedData[key] = value;
      }
    });

    final formData = FormData.fromMap(stringifiedData);

    if (audioFile != null) {
      formData.files.add(MapEntry('audio', audioFile));
    }

    await dio.put('$_endpoint/$id', data: formData);
  }

  // 7. Xóa bài nghe
  Future<void> deleteListeningComp(String id) async {
    await dio.delete('$_endpoint/$id');
  }
}