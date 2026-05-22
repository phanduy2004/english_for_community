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

  Future<List<WritingSubmissionEntity>> getTopicSubmissions(
      String topicId) async {
    // Gọi vào API bạn vừa tạo ở Backend
    final res = await dio.get('/writing/$topicId/submissions');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => WritingSubmissionEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/writing-topics/:id/start
  Future<({String submissionId, GeneratedPrompt generatedPrompt, bool resumed, String content})>
  startWriting({
    required String topicId,
    required String userId,
    required String taskType,
    bool freshStart = false,
    Map<String, dynamic>? fixedPrompt,
  }) async {
    final body = {
      'userId': userId,
      'taskType': taskType,
      if (freshStart) 'freshStart': true,
      if (fixedPrompt != null) 'fixedPrompt': fixedPrompt,
    };

    final res = await dio.post('/writing/$topicId/start', data: body);
    final map = res.data as Map<String, dynamic>;

    final submissionId = (map['submissionId'] ?? '') as String;

    // Server trả về prompt đã tạo
    final gp = GeneratedPrompt.fromJson(
        (map['generatedPrompt'] as Map<String, dynamic>?) ?? const {});

    final resumed = (map['resumed'] as bool?) ?? false;
    final content = (map['content'] as String?) ?? '';

    return (
    submissionId: submissionId,
    generatedPrompt: gp,
    resumed: resumed,
    content: content
    );
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

  Future<WritingSubmissionEntity> submitForReview({
    required String submissionId,
    required String content,
    // 👈 BỎ: required FeedbackEntity feedback (Server tự làm)
    required int durationInSeconds,
  }) async {
    final res = await dio.post(
      '/writing/$submissionId/submit',
      data: {
        'content': content,
        // 'feedback': ... -> BỎ
        'durationInSeconds': durationInSeconds,
      },
    );
    return WritingSubmissionEntity.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /api/writing/admin/all
  Future<List<WritingTopicEntity>> getAdminWritingTopics() async {
    final res = await dio.get('/writing/admin/all');
    final data = res.data as List<dynamic>;
    return data.map((e) => WritingTopicEntity.fromJson(e)).toList();
  }

  /// GET /api/writing/:id
  Future<WritingTopicEntity> getWritingTopicDetail(String id) async {
    final res = await dio.get('/writing/$id');
    return WritingTopicEntity.fromJson(res.data);
  }

  /// POST /api/writing
  Future<void> createWritingTopic(WritingTopicEntity topic) async {
    // Convert entity to JSON, loại bỏ id vì tạo mới server tự sinh
    final body = topic.toJson();
    body.remove('id'); // Xóa ID giả/rỗng
    body.remove('stats'); // Stats mặc định là 0
    await dio.post('/writing', data: body);
  }

  /// PUT /api/writing/:id
  Future<void> updateWritingTopic(WritingTopicEntity topic) async {
    final body = topic.toJson();
    body.remove('id');
    body.remove('stats'); // Không update stats từ client
    await dio.put('/writing/${topic.id}', data: body);
  }

  /// DELETE /api/writing/:id
  Future<void> deleteWritingTopic(String id) async {
    await dio.delete('/writing/$id');
  }

  Future<void> deleteSubmission(String submissionId) async {
    // Gọi đúng endpoint bạn đã định nghĩa ở backend route
    await dio.delete('/writing/submissions/$submissionId');
  }
}
