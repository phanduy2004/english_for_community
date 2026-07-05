import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/user_word_entity.dart';
import '../sqflite/dict_db.dart';

class UserVocabRemoteDatasource {
  final Dio dio;

  UserVocabRemoteDatasource({required this.dio});
  Future<List<UserWordEntity>> getDailyReminders() async {
    final response = await dio.get('/vocab/daily-reminders');

    // 🔥 SỬA LỖI Ở ĐÂY: Kiểm tra kiểu dữ liệu trước khi map
    final dynamic rawData = response.data['data'];

    // Trường hợp 1: Data là List chuẩn (ví dụ: [ {...}, {...} ])
    if (rawData is List) {
      return rawData.map((json) => UserWordEntity.fromMap(json)).toList();
    }

    // Trường hợp 2: Data là Map rỗng {} (Lỗi bạn đang gặp)
    // -> Coi như là danh sách rỗng
    if (rawData is Map) {
      return [];
    }

    // Trường hợp null hoặc kiểu lạ khác -> Trả về rỗng
    return [];
  }
  Future<List<UserWordEntity>> getLearningWords() async {
    final response = await dio.get('/vocab/learning');
    return (response.data as List)
        .map((json) => UserWordEntity.fromMap(json))
        .toList();
  }

  Future<List<UserWordEntity>> getRecentWords() async {
    final response = await dio.get('/vocab/recent');
    return (response.data as List)
        .map((json) => UserWordEntity.fromMap(json))
        .toList();
  }

  Future<List<UserWordEntity>> getSavedWords() async {
    final response = await dio.get('/vocab/saved');
    return (response.data as List)
        .map((json) => UserWordEntity.fromMap(json))
        .toList();
  }

  Future<List<UserWordEntity>> getWordsToReview() async {
    final response = await dio.get('/vocab/review');
    return (response.data as List)
        .map((json) => UserWordEntity.fromMap(json))
        .toList();
  }

  Future<void> saveWord(Entry entry) async {
    final String? ipa = entry.ipa;
    final String? pos = entry.pos;
    String? shortDef = entry.senses.isNotEmpty ? entry.senses.first.def : null;

    if (shortDef != null) {
      if (shortDef.contains(' ■ ')) shortDef = shortDef.split(' ■ ').last;
      if (shortDef.contains(' • ')) shortDef = shortDef.split(' • ').first;
    }

    final data = {
      'headword': entry.headword,
      'ipa': ipa,
      'shortDefinition': shortDef,
      'pos': pos,
    };

    await dio.post('/vocab/save', data: data);
  }

  Future<void> saveRawWord({
    required String headword,
    String? shortDefinition,
    String? pos,
  }) async {
    await dio.post('/vocab/save', data: {
      'headword': headword,
      'ipa': null,
      'shortDefinition': shortDefinition,
      'pos': pos,
    });
  }

  Future<void> startLearningWord(Entry entry) async {
    final String? ipa = entry.ipa;
    final String? pos = entry.pos;
    String? shortDef = entry.senses.isNotEmpty ? entry.senses.first.def : null;

    if (shortDef != null) {
      if (shortDef.contains(' ■ ')) shortDef = shortDef.split(' ■ ').last;
      if (shortDef.contains(' • ')) shortDef = shortDef.split(' • ').first;
    }

    final data = {
      'headword': entry.headword,
      'ipa': ipa,
      'shortDefinition': shortDef,
      'pos': pos,
    };

    await dio.post('/vocab/learn', data: data);
  }

  Future<void> logRecentWord(Entry entry) async {
    final data = {
      'headword': entry.headword,
      'ipa': entry.ipa,
      'shortDefinition': entry.senses.isNotEmpty
          ? entry.senses.first.def.split(' ■ ').last.split(' • ').first
          : null,
      'pos': entry.pos,
    };
    await dio.post('/vocab/recent', data: data);
  }

  Future<void> startLearningFromUserWord(UserWordEntity userWord) async {
    final data = {
      'headword': userWord.headword,
      'ipa': userWord.ipa,
      'shortDefinition': userWord.shortDefinition,
      'pos': userWord.pos,
    };
    await dio.post('/vocab/learn', data: data);
  }

  Future<void> submitReviewFeedback(String wordId, String feedback, int duration) async {
    await dio.post('/vocab/review-update', data: {
      'wordId': wordId,
      'feedback': feedback,
      'duration': duration,
    });
  }
}
