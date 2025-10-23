import 'package:english_for_community/core/entity/writing_topic_entity.dart';

import '../model/either.dart';
import '../model/failure.dart';

abstract class WritingRepository{
  Future<Either<Failure,List<WritingTopicEntity>>>  getWritingTopics();
}