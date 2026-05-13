import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import 'models/master_sampel.dart';
import 'models/master_lsu.dart';
import 'models/received_sample.dart';
import 'models/completed_sample.dart';
import 'models/aktivitas_sampel_pupuk.dart';
import 'models/data_sampel_pupuk.dart';
import 'models/kirim_dari_estate.dart';
import 'models/kirim_lab.dart';
import 'models/kirim_sertifikat_estate.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(path, version: 1, onCreate: _createDB);
    await _ensureSampelPupukTables(db);
    return db;
  }

  static Future<void> _ensureSampelPupukTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS data_sampel_pupuk (
        id INTEGER PRIMARY KEY,
        kode_sampel TEXT,
        jenis_pupuk_full TEXT,
        jenis_pupuk TEXT,
        merek TEXT,
        no_kode_sampel INTEGER,
        jumlah_sampel_zak INTEGER,
        no_segel TEXT,
        no_ba_sampel_pupuk TEXT,
        supplier TEXT,
        regional INTEGER,
        wilayah INTEGER,
        estate TEXT,
        pt TEXT,
        no_po TEXT,
        no_bpb TEXT,
        qty_partai_pengiriman INTEGER,
        qty_terima INTEGER,
        jenis_kendaraan TEXT,
        tanggal_pengambilan_sampel TEXT,
        tanggal_terima_dari_gudang TEXT,
        foto_terima_dari_gudang TEXT,
        tanggal_kirim_dari_estate TEXT,
        foto_kirim_dari_estate TEXT,
        tanggal_terima_dari_estate TEXT,
        foto_terima_dari_estate TEXT,
        tanggal_kirim_lab TEXT,
        foto_kirim_lab TEXT,
        kode_tracking TEXT,
        no_sertifikat TEXT,
        tanggal_kirim_sertifikat_estate TEXT,
        rekomendasi TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS terima_dari_gudang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_sampel_pupuk_id INTEGER NOT NULL,
        kode_sampel TEXT NOT NULL,
        tanggal_terima_dari_gudang TEXT NOT NULL,
        foto_terima_dari_gudang TEXT,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kirim_dari_estate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_sampel_pupuk_id INTEGER NOT NULL,
        kode_sampel TEXT NOT NULL,
        tanggal_kirim_dari_estate TEXT NOT NULL,
        foto_kirim_dari_estate TEXT,
        nama_pengirim TEXT,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS terima_dari_estate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_sampel_pupuk_id INTEGER NOT NULL,
        kode_sampel TEXT NOT NULL,
        tanggal_terima_dari_estate TEXT NOT NULL,
        foto_terima_dari_estate TEXT,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kirim_lab (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_sampel_pupuk_id INTEGER NOT NULL,
        kode_sampel TEXT NOT NULL,
        no_surat TEXT,
        tanggal_estimasi_kupa TEXT,
        tanggal_kirim_lab TEXT NOT NULL,
        foto_kirim_lab TEXT,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kirim_sertifikat_estate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_sampel_pupuk_id INTEGER NOT NULL,
        kode_sampel TEXT NOT NULL,
        tanggal_kirim_sertifikat_estate TEXT NOT NULL,
        rekomendasi TEXT,
        file_sertifikat TEXT,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db
        .execute("ALTER TABLE kirim_lab ADD COLUMN tanggal_estimasi_kupa TEXT")
        .catchError((_) {});
    await db
        .execute(
          "ALTER TABLE kirim_sertifikat_estate ADD COLUMN file_sertifikat TEXT",
        )
        .catchError((_) {});
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

    // Create completed_sample table
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

  // --- Data Sampel Pupuk ---
  Future<void> insertDataSampelPupukBatch(List<DataSampelPupuk> list) async {
    if (list.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final e in list) {
      batch.insert(
        'data_sampel_pupuk',
        e.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> clearDataSampelPupukByRegional(int? regional) async {
    final db = await database;
    if (regional == null) return await db.delete('data_sampel_pupuk');
    return await db.delete(
      'data_sampel_pupuk',
      where: 'regional = ?',
      whereArgs: [regional],
    );
  }

  Future<DataSampelPupuk?> getDataSampelPupukById(int id) async {
    final db = await database;
    final result = await db.query(
      'data_sampel_pupuk',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return DataSampelPupuk.fromJson(result.first);
  }

  /// Loads [DataSampelPupuk] and the latest local row per activity table for
  /// this sample (used for activity visibility on the detail screen).
  Future<AktivitasSampelPupuk?> getAktivitasSampelPupukByDataSampelPupukId(
    int dataSampelPupukId,
  ) async {
    final data = await getDataSampelPupukById(dataSampelPupukId);
    if (data == null) return null;

    final db = await database;

    Future<T?> latestForSample<T>(
      String table,
      T Function(Map<String, dynamic> json) parse,
    ) async {
      final rows = await db.query(
        table,
        where: 'data_sampel_pupuk_id = ?',
        whereArgs: [dataSampelPupukId],
        orderBy: 'id DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return parse(rows.first);
    }

    final kode = data.kodeSampel ?? '';

    return AktivitasSampelPupuk(
      id: data.id,
      kodeSampel: kode,
      dataSampelPupuk: data,
      kirimDariEstate: await latestForSample(
        'kirim_dari_estate',
        KirimDariEstate.fromJson,
      ),
      kirimLab: await latestForSample('kirim_lab', KirimLab.fromJson),
      kirimSertifikatEstate: await latestForSample(
        'kirim_sertifikat_estate',
        KirimSertifikatEstate.fromJson,
      ),
    );
  }

  Future<DataSampelPupuk?> getDataSampelPupukByKodeSampel(
    String kodeSampel,
  ) async {
    final db = await database;
    final result = await db.query(
      'data_sampel_pupuk',
      where: 'kode_sampel = ?',
      whereArgs: [kodeSampel],
    );
    if (result.isEmpty) return null;
    return DataSampelPupuk.fromJson(result.first);
  }

  /// Eligible for Type 5 (Kirim Sertifikat):
  /// - no_sertifikat is not null/empty
  /// - tanggal_kirim_sertifikat_estate is null/empty
  Future<List<DataSampelPupuk>>
  getEligibleDataSampelPupukKirimSertifikat() async {
    final db = await database;
    final result = await db.query(
      'data_sampel_pupuk',
      where:
          "(no_sertifikat IS NOT NULL AND TRIM(no_sertifikat) <> '') AND "
          "(tanggal_kirim_sertifikat_estate IS NULL OR TRIM(tanggal_kirim_sertifikat_estate) = '')",
      orderBy: 'kode_sampel ASC',
    );
    return result.map((e) => DataSampelPupuk.fromJson(e)).toList();
  }

  Future<int> updateDataSampelPupukTanggalKirimSertifikatEstate(
    int dataSampelPupukId,
    String isoDateTime,
  ) async {
    final db = await database;
    return await db.update(
      'data_sampel_pupuk',
      {
        'tanggal_kirim_sertifikat_estate': isoDateTime,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [dataSampelPupukId],
    );
  }

  // --- Kirim Dari Estate ---
  Future<int> insertKirimDariEstate(KirimDariEstate row) async {
    final db = await database;
    final map = row.toJson();
    map.remove('id');
    return await db.insert('kirim_dari_estate', map);
  }

  Future<List<KirimDariEstate>> getPendingKirimDariEstate() async {
    final db = await database;
    final result = await db.query(
      'kirim_dari_estate',
      where: 'status IN (?, ?)',
      whereArgs: ['not_uploaded', 'error'],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => KirimDariEstate.fromJson(e)).toList();
  }

  Future<List<KirimDariEstate>> getAllKirimDariEstate() async {
    final db = await database;
    final result = await db.query(
      'kirim_dari_estate',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => KirimDariEstate.fromJson(e)).toList();
  }

  Future<KirimDariEstate?> getKirimDariEstateById(int id) async {
    final db = await database;
    final result = await db.query(
      'kirim_dari_estate',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return KirimDariEstate.fromJson(result.first);
  }

  Future<int> deleteKirimDariEstate(int id) async {
    final db = await database;
    return await db.delete(
      'kirim_dari_estate',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateKirimDariEstateStatus(
    int id,
    String status, {
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'kirim_dari_estate',
      {
        'status': status,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Kirim Lab ---
  Future<int> insertKirimLab(KirimLab row) async {
    final db = await database;
    final map = row.toJson();
    map.remove('id');
    return await db.insert('kirim_lab', map);
  }

  Future<List<KirimLab>> getPendingKirimLab() async {
    final db = await database;
    final result = await db.query(
      'kirim_lab',
      where: 'status IN (?, ?)',
      whereArgs: ['not_uploaded', 'error'],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => KirimLab.fromJson(e)).toList();
  }

  Future<List<KirimLab>> getAllKirimLab() async {
    final db = await database;
    final result = await db.query('kirim_lab', orderBy: 'created_at DESC');
    return result.map((e) => KirimLab.fromJson(e)).toList();
  }

  Future<KirimLab?> getKirimLabById(int id) async {
    final db = await database;
    final result = await db.query(
      'kirim_lab',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return KirimLab.fromJson(result.first);
  }

  Future<int> deleteKirimLab(int id) async {
    final db = await database;
    return await db.delete('kirim_lab', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateKirimLabStatus(
    int id,
    String status, {
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'kirim_lab',
      {
        'status': status,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Kirim Sertifikat Estate ---
  Future<int> insertKirimSertifikatEstate(KirimSertifikatEstate row) async {
    final db = await database;
    final map = row.toJson();
    map.remove('id');
    return await db.insert('kirim_sertifikat_estate', map);
  }

  Future<List<KirimSertifikatEstate>> getPendingKirimSertifikatEstate() async {
    final db = await database;
    final result = await db.query(
      'kirim_sertifikat_estate',
      where: 'status IN (?, ?)',
      whereArgs: ['not_uploaded', 'error'],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => KirimSertifikatEstate.fromJson(e)).toList();
  }

  Future<List<KirimSertifikatEstate>> getAllKirimSertifikatEstate() async {
    final db = await database;
    final result = await db.query(
      'kirim_sertifikat_estate',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => KirimSertifikatEstate.fromJson(e)).toList();
  }

  Future<KirimSertifikatEstate?> getKirimSertifikatEstateById(int id) async {
    final db = await database;
    final result = await db.query(
      'kirim_sertifikat_estate',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return KirimSertifikatEstate.fromJson(result.first);
  }

  Future<int> deleteKirimSertifikatEstate(int id) async {
    final db = await database;
    return await db.delete(
      'kirim_sertifikat_estate',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateKirimSertifikatEstateStatus(
    int id,
    String status, {
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'kirim_sertifikat_estate',
      {
        'status': status,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
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
