import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/sqflite/dict_db.dart';

abstract class DictionaryRepository {
  /// Tìm kiếm từ vựng trong từ điển
  /// [query]: Từ cần tìm
  Future<Either<Failure, List<Entry>>> searchWord(
      String query, {
        int limit = 50,
      });
}