import '../sqflite/dict_db.dart';

class DictionaryLocalDatasource{

  final DictDb _dictDb = DictDb.I;
  Future<List<Entry>> searchWord(String query, {int limit = 50}) async {
    final rows = await _dictDb.search(query, limit: limit);
    return rows.map((row) => _dictDb.toEntry(row)).toList();
  }
}