import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DictDb {
  DictDb._();
  static final DictDb I = DictDb._();

  Database? _db;
  late String _dbPath;
  String get path => _dbPath;

  bool? _ftsOk;

  Future<Database> get db async => _db ??= await _open();

  static const String _assetDbPath = 'assets/db/dictionary.db';

  Future<Database> _open() async {
    // ✍️ Tăng số này mỗi khi thay file DB trong assets để buộc copy lại.
    const int myDbVersion = 1;

    final prefs = await SharedPreferences.getInstance();
    final int currentVersion = prefs.getInt('db_version') ?? 0;

    final dir = await getDatabasesPath();
    _dbPath = p.join(dir, 'dictionary.db');
    await Directory(dir).create(recursive: true);

    // Copy lại từ asset khi: (1) có phiên bản DB mới, HOẶC
    // (2) file hiện tại KHÔNG hợp lệ (thiếu bảng / rỗng / bị cắt dở).
    // Điều kiện (2) là mấu chốt sửa bug "cài lại báo no such table: entry":
    // cờ db_version trong SharedPreferences có thể bị Android Auto Backup khôi
    // phục (=1) trong khi file dictionary.db thật đã mất/rỗng sau khi gỡ app,
    // khiến logic cũ tưởng đã có DB nên bỏ qua bước copy.
    final bool needCopy =
        currentVersion < myDbVersion || !await _dbIsValid(_dbPath);

    if (needCopy) {
      if (kDebugMode) {
        debugPrint('[DictDb] (Re)install bundled DB '
            '(version $currentVersion -> $myDbVersion) -> $_dbPath');
      }
      await _installFromAsset(_dbPath);
      if (!await _dbIsValid(_dbPath)) {
        throw StateError('dictionary.db không hợp lệ sau khi copy từ asset: $_dbPath');
      }
      await prefs.setInt('db_version', myDbVersion);
    }

    final d = await openDatabase(_dbPath, readOnly: false);
    if (kDebugMode) {
      final t = await d.rawQuery(
          "SELECT name FROM sqlite_master WHERE type IN ('table','view') ORDER BY name");
      debugPrint('[DictDb] Opened. Tables=${t.map((e) => e['name']).toList()}');
    }
    return d;
  }

  /// Ghi file DB từ asset ra ổ đĩa một cách "nguyên tử": ghi ra file .tmp rồi
  /// rename. Nếu app bị kill giữa chừng, ta chỉ còn file .tmp dở dang chứ không
  /// để lại một dictionary.db cắt dở mà lần mở sau lại tưởng là hợp lệ.
  Future<void> _installFromAsset(String dbPath) async {
    final target = File(dbPath);
    final tmp = File('$dbPath.tmp');
    if (await target.exists()) await target.delete();
    if (await tmp.exists()) await tmp.delete();

    final bytes = await rootBundle.load(_assetDbPath);
    await tmp.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    await tmp.rename(dbPath);
  }

  /// Kiểm tra file DB có THẬT SỰ dùng được không: tồn tại, đủ lớn, mở được và
  /// có bảng dữ liệu ('entry' hoặc 'entries'). Trả false với file rỗng/hỏng để
  /// buộc copy lại từ asset.
  Future<bool> _dbIsValid(String dbPath) async {
    final f = File(dbPath);
    if (!await f.exists()) return false;
    // File từ điển thật ~225MB; file rỗng/cắt dở sẽ nhỏ hơn ngưỡng này rất nhiều.
    if (await f.length() < 100 * 1024) return false;

    Database? probe;
    try {
      probe = await openDatabase(dbPath, readOnly: true);
      final r = await probe.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type IN ('table','view') AND name IN ('entry','entries') LIMIT 1",
      );
      return r.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      await probe?.close();
    }
  }

  Future<String?> _mainTable(Database d) async {
    Future<bool> has(String name) async =>
        (await d.rawQuery("SELECT 1 FROM sqlite_master WHERE name=? LIMIT 1",[name])).isNotEmpty;
    if (await has('entry')) return 'entry';
    if (await has('entries')) return 'entries';
    return null;
  }

  Future<bool> _hasFts() async {
    if (_ftsOk != null) return _ftsOk!;
    final d = await db;
    try {
      final r = await d.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='entries_fts' LIMIT 1");
      if (r.isEmpty) {
        _ftsOk = false;
        return false;
      }
      await d.rawQuery("SELECT count(*) FROM entries_fts"); // probe
      _ftsOk = true;
      return true;
    } catch (_) {
      _ftsOk = false;
      return false;
    }
  }

  Future<List<Map<String, Object?>>> _prefix(String q, String table, int limit) async {
    final d = await db;
    final cols = await d.rawQuery('PRAGMA table_info($table)');
    final hasNorm = cols.any((c) => c['name'] == 'headword_norm');
    final col = hasNorm ? 'headword_norm' : 'headword';
    return d.rawQuery(
      'SELECT * FROM $table WHERE $col LIKE ? || "%" COLLATE NOCASE ORDER BY LENGTH($col), $col LIMIT ?',
      [q, limit],
    );
  }

  Future<List<Map<String, Object?>>> _fullText(String q, String table, int limit) async {
    final d = await db;
    if (await _hasFts()) {
      final term = q.replaceAll("'", "''");
      return d.rawQuery(
        "SELECT e.* FROM entries_fts f JOIN $table e ON e.id = f.rowid "
            "WHERE entries_fts MATCH ? LIMIT ?",
        [term, limit],
      );
    }
    final cols = await d.rawQuery('PRAGMA table_info($table)');
    final hasPlain = cols.any((c) => c['name'] == 'plain');
    if (hasPlain) {
      return d.rawQuery(
        'SELECT * FROM $table WHERE plain LIKE "%"||?||"%" OR headword LIKE "%"||?||"%" LIMIT ?',
        [q, q, limit],
      );
    }
    return d.rawQuery(
      'SELECT * FROM $table WHERE headword LIKE "%"||?||"%" LIMIT ?',
      [q, limit],
    );
  }

  /// API chính: prefix → full-text
  Future<List<Map<String, Object?>>> search(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) return [];
    final d = await db;
    final table = await _mainTable(d) ?? 'entry';
    final b = await _prefix(query, table, limit);
    if (b.isNotEmpty) return b;
    return _fullText(query, table, limit);
  }
  Entry toEntry(Map<String, Object?> row) => Entry.fromRow(row);
}

class Entry {
  final int id;
  final String headword;
  final String? ipa;
  final String? pos;
  final List<String> tags;
  final List<Sense> senses;
  final List<String> seeAlso;
  final String? source;

  Entry({
    required this.id,
    required this.headword,
    this.ipa,
    this.pos,
    required this.tags,
    required this.senses,
    required this.seeAlso,
    this.source,
  });

  factory Entry.fromRow(Map<String, Object?> r) {
    List<String> _arr(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => '$e').toList();
      if (v is String) {
        try {
          final d = json.decode(v);
          if (d is List) return d.map((e) => '$e').toList();
        } catch (_) {}
      }
      return const [];
    }

    List<Sense> _senses(dynamic v) {
      if (v == null) return const [];
      if (v is String) {
        try { v = json.decode(v); } catch (_) {}
      }
      if (v is List) {
        return v.map((e) => Sense.fromJson(e as Map<String, dynamic>)).toList();
      }
      return const [];
    }

    return Entry(
      id: (r['id'] as int?) ?? 0,
      headword: (r['headword'] as String?) ?? '',
      ipa: r['ipa'] as String?,
      pos: r['pos'] as String?,
      tags: _arr(r['tags_json']),
      senses: _senses(r['senses_json']),
      seeAlso: _arr(r['see_also_json']),
      source: r['source'] as String?,
    );
  }
}

class Sense {
  final String def;
  final List<String> examples;
  Sense({required this.def, required this.examples});
  factory Sense.fromJson(Map<String, dynamic> j) => Sense(
    def: (j['def'] ?? '').toString(),
    examples: (j['examples'] as List? ?? []).map((e) => e.toString()).toList(),
  );
}