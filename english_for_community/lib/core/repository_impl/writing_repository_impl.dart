import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/writing_remote_datasource.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';

import '../model/either.dart';
import '../model/failure.dart';
import '../repository/writing_repository.dart';

class WritingRepositoryImpl extends WritingRepository{
  final WritingRemoteDataSource writingRemoteDataSource;

  WritingRepositoryImpl({required this.writingRemoteDataSource});
  @override
  Future<Either<Failure,List<WritingTopicEntity>>> getWritingTopics() async {
    try {
      return Right(await writingRemoteDataSource.getWritingTopics());
    } on DioException catch (e) {
    return Left(WritingFailure(message: e.response?.data['message']));
    } catch (e) {
    return Left(WritingFailure(message: e.toString()));
    }
  }

}
