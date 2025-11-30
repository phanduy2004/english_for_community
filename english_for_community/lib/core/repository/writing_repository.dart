import 'package:english_for_community/core/entity/writing_topic_entity.dart';

import '../entity/writing_submission_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class WritingRepository {
  Future<Either<Failure, List<WritingTopicEntity>>> getWritingTopics();

  Future<Either<Failure, ({String submissionId, GeneratedPrompt generatedPrompt, bool resumed})>>
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
}