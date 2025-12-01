import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:sqflite/sqflite.dart';
import '../datasource/dictionary_local_datasource.dart';
import '../repository/dictionary_repository.dart';
import '../sqflite/dict_db.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  final DictionaryLocalDatasource dictionaryLocalDatasource;

  DictionaryRepositoryImpl({required this.dictionaryLocalDatasource});

  @override
  Future<Either<Failure, List<Entry>>> searchWord(String query,
      {int limit = 50}) async {
    try {
      final entries =
      await dictionaryLocalDatasource.searchWord(query, limit: limit);
      return Right(entries);
    } on DatabaseException catch (e) {
      return Left(DictionaryFailure(message: 'Lỗi DB: ${e.toString()}'));
    } catch (e) {
      return Left(DictionaryFailure(message: e.toString()));
    }
  }
}