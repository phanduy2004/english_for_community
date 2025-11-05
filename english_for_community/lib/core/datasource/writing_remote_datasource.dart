// writing_remote_data_source.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/entity/writing_submission_entity.dart';

class WritingRemoteDataSource {
  final Dio dio;
  WritingRemoteDataSource({required this.dio});

  /// GET /api/writing-topics
  Future<List<WritingTopicEntity>> getWritingTopics() async {
    final res = await dio.get('/writing');
    // res.data expected: List<dynamic>
    final data = res.data as List<dynamic>;
    return data
        .map((e) => WritingTopicEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/writing-topics/:id/start
  /// - Nếu FE đã sinh đề: truyền [generatedPrompt] để backend chỉ tạo submission.
  /// - Nếu không: để null, backend sẽ tự sinh đề (nếu bạn bật chế độ đó).
  /// Trả về: submissionId + generatedPrompt + resumed
  Future<({String submissionId, GeneratedPrompt generatedPrompt, bool resumed})>
  startWriting({
    required String topicId,
    required String userId,
    GeneratedPrompt? generatedPrompt,
  }) async {
    final body = {
      'userId': userId,
      if (generatedPrompt != null) 'generatedPrompt': generatedPrompt.toJson(),
    };

    final res = await dio.post('/api/writing-topics/$topicId/start', data: body);
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

  /// GET /api/submissions/:id
  Future<WritingSubmissionEntity> getSubmission(String submissionId) async {
    final res = await dio.get('/api/submissions/$submissionId');
    return WritingSubmissionEntity.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /api/submissions/:id/draft  (autosave nháp)
  /// Body: { content }
  Future<WritingSubmissionEntity> autosaveDraft({
    required String submissionId,
    required String content,
  }) async {
    final res = await dio.patch(
      '/api/submissions/$submissionId/draft',
      data: {'content': content},
    );
    final map = res.data as Map<String, dynamic>;
    final sub = map['submission'] as Map<String, dynamic>?;
    if (sub == null) {
      throw StateError('autosaveDraft: missing submission in response');
    }
    return WritingSubmissionEntity.fromJson(sub);
  }

  /// POST /api/submissions/:id/submit  (lưu bài nộp, KHÔNG chấm ở backend)
  /// Body: { content }
  Future<void> submitEssay({
    required String submissionId,
    required String content,
  }) async {
    await dio.post(
      '/api/submissions/$submissionId/submit',
      data: {'content': content},
    );
  }

  /// POST /api/submissions/:id/feedback  (FE chấm xong rồi đẩy feedback lên)
  /// Body: { feedback: {...} }
  Future<void> uploadFeedback({
    required String submissionId,
    required FeedbackEntity feedback,
  }) async {
    await dio.post(
      '/api/submissions/$submissionId/feedback',
      data: {'feedback': feedback.toJson()},
    );
  }
}
