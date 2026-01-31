import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import 'models/master_sampel.dart';
import 'models/master_lsu.dart';
import 'models/received_sample.dart';
import 'models/completed_sample.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lsu_scanner.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
    await _ensureCompletedSampleTable(db);
    return db;
  }

  /// Ensures completed_sample exists (handles DBs created at v2 before table was in onCreate).
  Future<void> _ensureCompletedSampleTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='completed_sample'",
    );
    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE completed_sample (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data_lsu_id INTEGER NOT NULL UNIQUE,
          master_lsu_id INTEGER NOT NULL,
          kode TEXT NOT NULL,
          tanggal_selesai TEXT NOT NULL,
          waktu_selesai TEXT NOT NULL,
          foto_path TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'not_uploaded',
          error_message TEXT,
          user_id INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (master_lsu_id) REFERENCES master_lsu(id)
        )
      ''');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE completed_sample (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data_lsu_id INTEGER NOT NULL UNIQUE,
          master_lsu_id INTEGER NOT NULL,
          kode TEXT NOT NULL,
          tanggal_selesai TEXT NOT NULL,
          waktu_selesai TEXT NOT NULL,
          foto_path TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'not_uploaded',
          error_message TEXT,
          user_id INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (master_lsu_id) REFERENCES master_lsu(id)
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    // Create master_sampel table
    await db.execute('''
      CREATE TABLE master_sampel (
        id INTEGER PRIMARY KEY,
        nama TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create master_lsu table
    await db.execute('''
      CREATE TABLE master_lsu (
        id INTEGER PRIMARY KEY,
        regional INTEGER NOT NULL,
        pt TEXT,
        status_kebun TEXT,
        estate TEXT,
        wilayah INTEGER,
        afdeling TEXT,
        blok TEXT,
        group_blok TEXT,
        tahun_tanam INTEGER,
        varietas TEXT,
        jenis_tanah TEXT,
        topografi TEXT,
        luas_ha TEXT,
        jml_pokok INTEGER,
        jml_pokok_produktif INTEGER,
        sph INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create received_sample table (data_lsu_id unique to prevent duplicate receives)
    await db.execute('''
      CREATE TABLE received_sample (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_lsu_id INTEGER NOT NULL UNIQUE,
        master_lsu_id INTEGER NOT NULL,
        kode TEXT NOT NULL,
        tanggal_terima TEXT NOT NULL,
        waktu_terima TEXT NOT NULL,
        foto_path TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        user_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (master_lsu_id) REFERENCES master_lsu(id)
      )
    ''');

    // Create completed_sample table (for version 2; also in onUpgrade for existing DBs)
    if (version >= 2) {
      await db.execute('''
        CREATE TABLE completed_sample (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data_lsu_id INTEGER NOT NULL UNIQUE,
          master_lsu_id INTEGER NOT NULL,
          kode TEXT NOT NULL,
          tanggal_selesai TEXT NOT NULL,
          waktu_selesai TEXT NOT NULL,
          foto_path TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'not_uploaded',
          error_message TEXT,
          user_id INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (master_lsu_id) REFERENCES master_lsu(id)
        )
      ''');
    }

    // Create user_preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  // Master Sampel methods
  Future<int> insertMasterSampel(MasterSampel sampel) async {
    final db = await database;
    return await db.insert('master_sampel', sampel.toJson());
  }

  Future<void> insertMasterSampelBatch(List<MasterSampel> sampels) async {
    final db = await database;
    final batch = db.batch();
    for (final sampel in sampels) {
      batch.insert('master_sampel', sampel.toJson());
    }
    await batch.commit(noResult: true);
  }

  Future<List<MasterSampel>> getAllMasterSampel() async {
    final db = await database;
    final result = await db.query('master_sampel');
    return result.map((json) => MasterSampel.fromJson(json)).toList();
  }

  Future<int> clearMasterSampel() async {
    final db = await database;
    return await db.delete('master_sampel');
  }

  // Master LSU methods
  Future<int> insertMasterLsu(MasterLsu lsu) async {
    final db = await database;
    return await db.insert('master_lsu', lsu.toJson());
  }

  Future<void> insertMasterLsuBatch(List<MasterLsu> lsus) async {
    final db = await database;
    final batch = db.batch();
    for (final lsu in lsus) {
      batch.insert('master_lsu', lsu.toJson());
    }
    await batch.commit(noResult: true);
  }

  Future<MasterLsu?> getMasterLsuById(int id) async {
    final db = await database;
    final result = await db.query(
      'master_lsu',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return MasterLsu.fromJson(result.first);
  }

  Future<List<MasterLsu>> getAllMasterLsu() async {
    final db = await database;
    final result = await db.query('master_lsu');
    return result.map((json) => MasterLsu.fromJson(json)).toList();
  }

  Future<List<MasterLsu>> getMasterLsuByRegional(int regional) async {
    final db = await database;
    final result = await db.query(
      'master_lsu',
      where: 'regional = ?',
      whereArgs: [regional],
    );
    return result.map((json) => MasterLsu.fromJson(json)).toList();
  }

  Future<int> clearMasterLsu() async {
    final db = await database;
    return await db.delete('master_lsu');
  }

  // Received Sample methods
  Future<int> insertReceivedSample(ReceivedSample sample) async {
    final db = await database;
    return await db.insert('received_sample', sample.toJson());
  }

  Future<List<ReceivedSample>> getAllReceivedSamples() async {
    final db = await database;
    final result = await db.query(
      'received_sample',
      orderBy: 'created_at DESC',
    );
    return result.map((json) => ReceivedSample.fromJson(json)).toList();
  }

  Future<List<ReceivedSample>> getPendingUploads() async {
    final db = await database;
    final result = await db.query(
      'received_sample',
      where: 'status IN (?, ?)',
      whereArgs: ['not_uploaded', 'error'],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => ReceivedSample.fromJson(json)).toList();
  }

  Future<List<ReceivedSample>> getUploadedSamples() async {
    final db = await database;
    final result = await db.query(
      'received_sample',
      where: 'status = ?',
      whereArgs: [AppConstants.statusUploaded],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => ReceivedSample.fromJson(json)).toList();
  }

  Future<ReceivedSample?> getReceivedSampleById(int id) async {
    final db = await database;
    final result = await db.query(
      'received_sample',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return ReceivedSample.fromJson(result.first);
  }

  /// Returns existing received sample for this data_lsu_id if any (unique constraint).
  Future<ReceivedSample?> getReceivedSampleByDataLsuId(int dataLsuId) async {
    final db = await database;
    final result = await db.query(
      'received_sample',
      where: 'data_lsu_id = ?',
      whereArgs: [dataLsuId],
    );
    if (result.isEmpty) return null;
    return ReceivedSample.fromJson(result.first);
  }

  Future<int> updateReceivedSampleStatus(
    int id,
    String status, {
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'received_sample',
      {
        'status': status,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReceivedSample(int id) async {
    final db = await database;
    return await db.delete('received_sample', where: 'id = ?', whereArgs: [id]);
  }

  // Completed Sample methods
  Future<int> insertCompletedSample(CompletedSample sample) async {
    final db = await database;
    return await db.insert('completed_sample', sample.toJson());
  }

  Future<List<CompletedSample>> getAllCompletedSamples() async {
    final db = await database;
    final result = await db.query(
      'completed_sample',
      orderBy: 'created_at DESC',
    );
    return result.map((json) => CompletedSample.fromJson(json)).toList();
  }

  Future<List<CompletedSample>> getPendingCompleteUploads() async {
    final db = await database;
    final result = await db.query(
      'completed_sample',
      where: 'status IN (?, ?)',
      whereArgs: ['not_uploaded', 'error'],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => CompletedSample.fromJson(json)).toList();
  }

  Future<CompletedSample?> getCompletedSampleById(int id) async {
    final db = await database;
    final result = await db.query(
      'completed_sample',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return CompletedSample.fromJson(result.first);
  }

  Future<CompletedSample?> getCompletedSampleByDataLsuId(int dataLsuId) async {
    final db = await database;
    final result = await db.query(
      'completed_sample',
      where: 'data_lsu_id = ?',
      whereArgs: [dataLsuId],
    );
    if (result.isEmpty) return null;
    return CompletedSample.fromJson(result.first);
  }

  Future<int> updateCompletedSampleStatus(
    int id,
    String status, {
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'completed_sample',
      {
        'status': status,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCompletedSample(int id) async {
    final db = await database;
    return await db.delete(
      'completed_sample',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User Preferences methods
  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert('user_preferences', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getPreference(String key) async {
    final db = await database;
    final result = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> deletePreference(String key) async {
    final db = await database;
    await db.delete('user_preferences', where: 'key = ?', whereArgs: [key]);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
