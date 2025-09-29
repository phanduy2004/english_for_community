import '../entity/listening_entity.dart';
import '../model/either.dart';
import '../model/failure.dart';

abstract class ListeningRepository{
  Future<Either<Failure, ListeningEntity>> getListeningById(String Id);
  Future<Either<Failure, List<ListeningEntity>>> getListListening();
}