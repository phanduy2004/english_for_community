// lib/core/datasource/writing_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';

class WritingRemoteDataSource {
  final Dio dio;
  WritingRemoteDataSource({required this.dio});

  /// GET /api/writing-topics
  Future<List<WritingTopicEntity>> getWritingTopics() async {
    // ✍️ SỬA PATH: API của bạn là '/writing-topics'
    final res = await dio.get('/writing');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => WritingTopicEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  Future<List<WritingSubmissionEntity>> getTopicSubmissions(String topicId) async {
    // Gọi vào API bạn vừa tạo ở Backend
    final res = await dio.get('/writing/$topicId/submissions');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => WritingSubmissionEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  /// POST /api/writing-topics/:id/start
  Future<({String submissionId, GeneratedPrompt generatedPrompt, bool resumed})>
  startWriting({
    required String topicId,
    required String userId,
    required GeneratedPrompt generatedPrompt, // ✍️ BẮT BUỘC CÓ
  }) async {
    final body = {
      'userId': userId,
      'generatedPrompt': generatedPrompt.toJson(),
    };

    // ✍️ SỬA PATH: API của bạn là '/api/writing-topics/:id/start'
    final res = await dio.post('/writing/$topicId/start', data: body);
    final map = res.data as Map<String, dynamic>;
    final submissionId = (map['submissionId'] ?? '') as String;
    if (submissionId.isEmpty) {
      throw StateError('startWriting: missing submissionId');
    }
    final gp = GeneratedPrompt.fromJson(
        (map['generatedPrompt'] as Map<String, dynamic>?) ?? const {});
    final resumed = (map['resumed'] as bool?) ?? false;
    return (submissionId: submissionId, generatedPrompt: gp, resumed: resumed);
  }

  /// GET /api/submissions/:id (Hàm này bạn chưa có, nhưng nên có)
  Future<WritingSubmissionEntity> getSubmission(String submissionId) async {
    // ✍️ SỬA PATH: API có thể là '/api/writing-submissions/:id'
    final res = await dio.get('/writing/$submissionId');
    return WritingSubmissionEntity.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /api/writing-submissions/:id/draft (Autosave)
  Future<int> autosaveDraft({
    required String submissionId,
    required String content,
  }) async {
    final res = await dio.patch(
      '/writing/$submissionId/draft', // ✍️ SỬA PATH
      data: {'content': content},
    );
    final map = res.data as Map<String, dynamic>;
    // ✍️ SỬA RESPONSE: API trả về { message, wordCount }
    return (map['wordCount'] as int?) ?? 0;
  }


  /// POST /api/writing-submissions/:id/submit (Lưu bài nộp, feedback, và duration)
  /// ✍️ HÀM NÀY SỬA HOÀN TOÀN ĐỂ KHỚP VỚI CONTROLLER
  Future<WritingSubmissionEntity> submitForReview({
    required String submissionId,
    required String content,
    required FeedbackEntity feedback,
    required int durationInSeconds,
  }) async {
    final res = await dio.post(
      '/writing/$submissionId/submit', // ✍️ SỬA PATH
      data: {
        'content': content,
        'feedback': feedback.toJson(),
        'durationInSeconds': durationInSeconds,
      },
    );
    // API trả về submission đã được cập nhật
    return WritingSubmissionEntity.fromJson(res.data as Map<String, dynamic>);
  }
}