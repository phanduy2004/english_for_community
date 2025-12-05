import 'package:english_for_community/core/entity/writing_topic_entity.dart';

import '../entity/writing_submission_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class WritingRepository {
  Future<Either<Failure, List<WritingTopicEntity>>> getWritingTopics();

// 👇 SỬA DÒNG NÀY: Thêm 'String content' vào trong record return
  Future<Either<Failure, ({String submissionId, GeneratedPrompt generatedPrompt, bool resumed, String content})>>
  startWriting({
    required String topicId,
    required String userId,
    required GeneratedPrompt generatedPrompt,
  });
  Future<Either<Failure, WritingSubmissionEntity>> submitForReview({
    required String submissionId,
    required String content,
    required FeedbackEntity feedback,
    required int durationInSeconds,
  });
  Future<Either<Failure, List<WritingSubmissionEntity>>> getTopicSubmissions(String topicId);
  Future<Either<Failure, void>> deleteSubmission(String submissionId);

  Future<Either<Failure, void>> saveDraft({
    required String submissionId,
    required String content,
  });

  Future<Either<Failure, List<WritingTopicEntity>>> getAdminWritingTopics();
  Future<Either<Failure, WritingTopicEntity>> getWritingTopicDetail(String id);
  Future<Either<Failure, void>> createWritingTopic(WritingTopicEntity topic);
  Future<Either<Failure, void>> updateWritingTopic(WritingTopicEntity topic);
  Future<Either<Failure, void>> deleteWritingTopic(String id);
}