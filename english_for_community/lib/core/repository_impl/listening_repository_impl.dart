import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/listening_remote_datasource.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/listening_repository.dart';

class ListeningRepositoryImpl implements ListeningRepository{
  final ListeningRemoteDatasource listeningRemoteDatasource;

  ListeningRepositoryImpl({required this.listeningRemoteDatasource});

  @override
  Future<Either<Failure, ListeningEntity>> getListeningById(String Id) async {
    try {
      return Right(await listeningRemoteDatasource.getListeningById(Id));
    } on DioException catch (e) {
    return Left(ListeningFailure(message: e.response?.data['message']));
    } catch (e) {
    return Left(ListeningFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ListeningEntity>>> getListListening()async {
    try {
      return Right((await listeningRemoteDatasource.getListListening()) as List<ListeningEntity>);
    } on DioException catch (e) {
    return Left(ListeningFailure(message: e.response?.data['message']));
    } catch (e) {
    return Left(ListeningFailure(message: e.toString()));
    }
  }

}