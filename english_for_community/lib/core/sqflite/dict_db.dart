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

  Future<Database> _open() async {
    // ✍️ BƯỚC 1: Đặt phiên bản DB mới của bạn
    // (Giả sử file DB mới trong assets là bản 1)
    const int myDbVersion = 1;

    final prefs = await SharedPreferences.getInstance();
    int currentVersion = prefs.getInt('db_version') ?? 0;

    final dir = await getDatabasesPath();
    _dbPath = p.join(dir, 'dictionary.db');

    if (currentVersion < myDbVersion) {
      if (kDebugMode) debugPrint('[DictDb] Phát hiện phiên bản DB mới. Đang xóa file cũ...');
      // Xóa file DB cũ đi
      if (await File(_dbPath).exists()) {
        await File(_dbPath).delete();
        if (kDebugMode) debugPrint('[DictD] Đã xóa DB cũ (phiên bản $currentVersion)');
      }
      // Cập nhật phiên bản đã lưu
      await prefs.setInt('db_version', myDbVersion);
    }

    if (!await File(_dbPath).exists()) {
      await Directory(dir).create(recursive: true);
      final bytes = await rootBundle.load('assets/db/dictionary.db');
      await File(_dbPath).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      if (kDebugMode) debugPrint('[DictDb] Đã copy file DB mới (phiên bản $myDbVersion) -> $_dbPath');
    }

    final d = await openDatabase(_dbPath, readOnly: false);
    if (kDebugMode) {
      final t = await d.rawQuery(
          "SELECT name FROM sqlite_master WHERE type IN ('table','view') ORDER BY name");
      debugPrint('[DictDb] Opened. Tables=${t.map((e)=>e['name']).toList()}');
    }
    return d;
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