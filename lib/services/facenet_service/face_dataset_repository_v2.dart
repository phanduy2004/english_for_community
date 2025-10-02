// lib/services/face_dataset_repository_sqlite.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:recognize_face/utils/values.dart' show threshold;

class FaceDatasetRepositorySqlite {
  static const _dbName = 'face_embeddings.db';
  // 🔼 Bump version để chạy migration thêm cột avatar
  static const _dbVersion = 2;

  static const _tablePerson = 'person';
  static const _tableEmbedding = 'embedding';
  static const _tableConfig = 'config';

  Database? _db;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tablePerson (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            image_count INTEGER NOT NULL DEFAULT 0,
            avatar BLOB NULL           
          )
        ''');

        await db.execute('''
          CREATE TABLE $_tableEmbedding (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_id INTEGER NOT NULL,
            vector BLOB NOT NULL,
            dims INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(person_id) REFERENCES $_tablePerson(id)
            ON DELETE CASCADE
          )
        ''');

        await db.execute('CREATE INDEX idx_embedding_person ON $_tableEmbedding(person_id)');

        await db.execute('''
          CREATE TABLE $_tableConfig (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        // seed config mặc định (tương tự JSON cũ)
        await db.insert(_tableConfig, {'key': 'width', 'value': '160'});
        await db.insert(_tableConfig, {'key': 'height', 'value': '160'});
        await db.insert(_tableConfig, {'key': 'threshold', 'value': threshold.toString()});
        await db.insert(_tableConfig, {
          'key': 'normalization',
          'value': '(pixel - 128.0) / 128.0'
        });
        await db.insert(_tableConfig, {
          'key': 'preprocess',
          'value': jsonEncode({
            'detect': 'mlkit',
            'bbox_margin': 0.10,
            'denoise': true,
            'brightness_gain': 1.05,
            'contrast_gain': 1.10
          })
        });
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // Thêm cột avatar cho person (giữ dữ liệu cũ)
          await db.execute('ALTER TABLE $_tablePerson ADD COLUMN avatar BLOB NULL');
        }
      },
    );

    return _db!;
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // ===== Helpers: serialize double[] <-> BLOB =====

  Uint8List _doublesToBytes(List<double> v) {
    final bd = ByteData(v.length * 8);
    for (int i = 0; i < v.length; i++) {
      bd.setFloat64(i * 8, v[i], Endian.little);
    }
    return bd.buffer.asUint8List();
  }

  List<double> _bytesToDoubles(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final n = bytes.length ~/ 8;
    return List<double>.generate(n, (i) => bd.getFloat64(i * 8, Endian.little));
  }

  // ===== CRUD chính =====

  /// Thêm embeddings cho 1 người; nếu người chưa có thì tạo mới.
  /// Có thể truyền kèm avatarBytes (JPEG/PNG) để set avatar ngay (tuỳ chọn).
  Future<void> addEmbeddings({
    required String personName,
    required List<List<double>> embeddings,
    Uint8List? avatarBytes, // 👈 optional
  }) async {
    final db = await _openDb();

    await db.transaction((txn) async {
      // tìm hoặc tạo person
      int personId;
      final exist = await txn.query(
        _tablePerson,
        where: 'name = ?',
        whereArgs: [personName],
        limit: 1,
      );
      if (exist.isEmpty) {
        personId = await txn.insert(_tablePerson, {
          'name': personName,
          'image_count': 0,
          'avatar': avatarBytes, // nếu có thì set luôn
        });
      } else {
        personId = exist.first['id'] as int;
        // nếu có avatar mới và hiện chưa có -> cập nhật
        if (avatarBytes != null && (exist.first['avatar'] == null)) {
          await txn.update(
            _tablePerson,
            {'avatar': avatarBytes},
            where: 'id = ?',
            whereArgs: [personId],
          );
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      // chèn từng embedding (BLOB)
      for (final e in embeddings) {
        final blob = _doublesToBytes(e);
        await txn.insert(_tableEmbedding, {
          'person_id': personId,
          'vector': blob,
          'dims': e.length,
          'created_at': now,
        });
      }

      // cập nhật image_count
      await txn.rawUpdate(
        'UPDATE $_tablePerson SET image_count = image_count + ? WHERE id = ?',
        [embeddings.length, personId],
      );
    });
  }

  /// Lấy tất cả embeddings của một người theo name.
  Future<List<List<double>>> getEmbeddingsByName(String personName) async {
    final db = await _openDb();
    final rows = await db.rawQuery('''
      SELECT e.vector FROM $_tableEmbedding e
      JOIN $_tablePerson p ON p.id = e.person_id
      WHERE p.name = ?
      ORDER BY e.id ASC
    ''', [personName]);

    return rows.map((r) => _bytesToDoubles(r['vector'] as Uint8List)).toList();
  }

  /// Lấy danh sách user. withAvatar=false (mặc định) để tránh load nặng.
  /// Nếu withAvatar=true, kết quả có thêm khoá 'avatar' (Uint8List?).
  Future<List<Map<String, dynamic>>> listUsers({bool withAvatar = false}) async {
    final db = await _openDb();
    if (withAvatar) {
      return db.query(
        _tablePerson,
        columns: ['id', 'name', 'image_count', 'avatar'],
        orderBy: 'name COLLATE NOCASE',
      );
    }
    return db.query(
      _tablePerson,
      columns: ['id', 'name', 'image_count'],
      orderBy: 'name COLLATE NOCASE',
    );
  }

  /// Đổi tên user theo id.
  Future<void> renameUser({required int id, required String newName}) async {
    final db = await _openDb();
    await db.update(
      _tablePerson,
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort, // tránh trùng tên
    );
  }

  /// Xoá user theo id (cascading xoá luôn embeddings).
  Future<void> deleteUserById(int id) async {
    final db = await _openDb();
    await db.delete(_tablePerson, where: 'id = ?', whereArgs: [id]);
  }

  /// Xóa một người theo name (cascading sẽ xóa luôn embeddings)
  Future<void> deleteUserByName(String personName) async {
    final db = await _openDb();
    await db.delete(_tablePerson, where: 'name = ?', whereArgs: [personName]);
  }

  // ===== Avatar APIs =====

  /// Set/replace avatar theo id.
  Future<void> setAvatarById(int id, Uint8List avatarBytes) async {
    final db = await _openDb();
    await db.update(
      _tablePerson,
      {'avatar': avatarBytes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Set/replace avatar theo name.
  Future<void> setAvatarByName(String name, Uint8List avatarBytes) async {
    final db = await _openDb();
    await db.update(
      _tablePerson,
      {'avatar': avatarBytes},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  /// Xoá avatar theo id (giữ user & embeddings).
  Future<void> clearAvatarById(int id) async {
    final db = await _openDb();
    await db.update(
      _tablePerson,
      {'avatar': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Lấy avatar theo id.
  Future<Uint8List?> getAvatarById(int id) async {
    final db = await _openDb();
    final r = await db.query(
      _tablePerson,
      columns: ['avatar'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (r.isEmpty) return null;
    return r.first['avatar'] as Uint8List?;
  }

  /// Lấy avatar theo name.
  Future<Uint8List?> getAvatarByName(String name) async {
    final db = await _openDb();
    final r = await db.query(
      _tablePerson,
      columns: ['avatar'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (r.isEmpty) return null;
    return r.first['avatar'] as Uint8List?;
  }

  // ===== Config & summary =====

  Future<void> upsertConfig(String key, String value) async {
    final db = await _openDb();
    await db.insert(
      _tableConfig,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getConfig(String key) async {
    final db = await _openDb();
    final r = await db.query(_tableConfig, where: 'key = ?', whereArgs: [key], limit: 1);
    if (r.isEmpty) return null;
    return r.first['value'] as String;
  }

  Future<Map<String, int>> getSummary() async {
    final db = await _openDb();
    final totalUsers = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tablePerson'),
    ) ?? 0;
    final totalProcessed = Sqflite.firstIntValue(
      await db.rawQuery('SELECT IFNULL(SUM(image_count), 0) FROM $_tablePerson'),
    ) ?? 0;
    return {
      'total_users': totalUsers,
      'total_processed': totalProcessed,
      'total_errors': 0,
    };
  }

  /// Xuất tất cả ra JSON-like (kèm avatar base64 để backup/đổi máy nếu muốn).
  Future<Map<String, dynamic>> exportAsJsonLike({bool includeAvatarBase64 = true}) async {
    final db = await _openDb();

    final users = await db.query(_tablePerson, orderBy: 'name COLLATE NOCASE');
    final List<Map<String, dynamic>> usersJson = [];

    for (final u in users) {
      final personId = u['id'] as int;
      final name = u['name'] as String;
      final imageCount = u['image_count'] as int;
      final avatar = u['avatar'] as Uint8List?;

      final embRows = await db.query(
        _tableEmbedding,
        columns: ['vector', 'dims'],
        where: 'person_id = ?',
        whereArgs: [personId],
        orderBy: 'id ASC',
      );

      final embeddings = embRows
          .map((r) => _bytesToDoubles(r['vector'] as Uint8List))
          .toList(growable: false);

      usersJson.add({
        'name': name,
        'embeddings': embeddings,
        'image_count': imageCount,
        'processed': imageCount,
        'errors': 0,
        if (includeAvatarBase64 && avatar != null)
          'avatar_b64': base64Encode(avatar),
      });
    }

    final width = int.tryParse(await getConfig('width') ?? '') ?? 160;
    final height = int.tryParse(await getConfig('height') ?? '') ?? 160;
    final th = double.tryParse(await getConfig('threshold') ?? '') ?? threshold;
    final normalization = await getConfig('normalization') ?? '(pixel - 128.0) / 128.0';
    final preprocess = await getConfig('preprocess');

    final summary = await getSummary();

    return {
      'users': usersJson,
      'config': {
        'width': width,
        'height': height,
        'threshold': th,
        'normalization': normalization,
        'preprocess': preprocess != null ? jsonDecode(preprocess) : {},
      },
      'summary': summary,
    };
  }

  /// Đường dẫn file DB (debug/backup)
  Future<String> getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbName);
  }

  /// Xoá DB. Nếu recreateEmpty=true thì tạo lại schema trống.
  Future<void> deleteDatabaseFile({bool recreateEmpty = true}) async {
    final path = await getDatabasePath();
    await close();
    await deleteDatabase(path);
    if (recreateEmpty) {
      await _openDb();
    }
  }

  /// Xoá toàn bộ dữ liệu (users + embeddings). Giữ schema.
  Future<void> clearAll() async {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete(_tableEmbedding);
      await txn.delete(_tablePerson);
    });
  }
}
