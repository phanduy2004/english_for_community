// lib/core/repository_impl/writing_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/writing_remote_datasource.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
// ⬇️ THÊM IMPORT
import 'package:english_for_community/core/entity/writing_submission_entity.dart';

import '../model/either.dart';
import '../model/failure.dart';
import '../repository/writing_repository.dart';

class WritingRepositoryImpl extends WritingRepository { // ✍️ Sửa: implements
  final WritingRemoteDataSource writingRemoteDataSource;

  WritingRepositoryImpl({required this.writingRemoteDataSource});
  @override
  Future<Either<Failure, List<WritingTopicEntity>>> getWritingTopics() async {
    try {
      return Right(await writingRemoteDataSource.getWritingTopics());
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message']));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }

  // --- ⬇️ THÊM CÁC HÀM IMPLEMENT MỚI ⬇️ ---
  @override
  Future<Either<Failure, List<WritingSubmissionEntity>>> getTopicSubmissions(String topicId) async {
    try {
      final result = await writingRemoteDataSource.getTopicSubmissions(topicId);
      return Right(result);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ({String submissionId, GeneratedPrompt generatedPrompt, bool resumed, String content})>> // 👈 Thêm String content
  startWriting({
    required String topicId,
    required String userId,
    required GeneratedPrompt generatedPrompt,
  }) async {
    try {
      final result = await writingRemoteDataSource.startWriting(
        topicId: topicId,
        userId: userId,
        generatedPrompt: generatedPrompt,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message']));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> saveDraft({
    required String submissionId,
    required String content,
  }) async {
    try {
      // Gọi AutosaveDraft trong datasource (bạn có thể đổi tên hàm trong datasource cho khớp nếu muốn)
      await writingRemoteDataSource.autosaveDraft(
        submissionId: submissionId,
        content: content,
      );
      return Right(null);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, WritingSubmissionEntity>> submitForReview({
    required String submissionId,
    required String content,
    required FeedbackEntity feedback,
    required int durationInSeconds,
  }) async {
    try {
      final result = await writingRemoteDataSource.submitForReview(
        submissionId: submissionId,
        content: content,
        feedback: feedback,
        durationInSeconds: durationInSeconds,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message']));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> deleteSubmission(String submissionId) async {
    try {
      await writingRemoteDataSource.deleteSubmission(submissionId);
      return Right(null);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }
// 👇 IMPLEMENT ADMIN METHODS 👇

  @override
  Future<Either<Failure, List<WritingTopicEntity>>> getAdminWritingTopics() async {
    try {
      final result = await writingRemoteDataSource.getAdminWritingTopics();
      return Right(result);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WritingTopicEntity>> getWritingTopicDetail(String id) async {
    try {
      final result = await writingRemoteDataSource.getWritingTopicDetail(id);
      return Right(result);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createWritingTopic(WritingTopicEntity topic) async {
    try {
      await writingRemoteDataSource.createWritingTopic(topic);
      return Right(null);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWritingTopic(WritingTopicEntity topic) async {
    try {
      await writingRemoteDataSource.updateWritingTopic(topic);
      return Right(null);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWritingTopic(String id) async {
    try {
      await writingRemoteDataSource.deleteWritingTopic(id);
      return Right(null);
    } on DioException catch (e) {
      return Left(WritingFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(WritingFailure(message: e.toString()));
    }
  }
// (Bạn có thể thêm getSubmission và autosaveDraft nếu BLoC cần)
}