import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/aktivitas_sampel_pupuk.dart';
import '../models/data_sampel_pupuk.dart';
import 'kirim_dari_estate_dao.dart';
import 'kirim_lab_dao.dart';
import 'kirim_sertifikat_estate_dao.dart';

/// Synced `data_sampel_pupuk` records (lookup after QR scan, lists, eligibility).
class DataSampelPupukDao {
  DataSampelPupukDao(this._appDatabase)
    : _kirimDariEstate = KirimDariEstateDao(_appDatabase),
      _kirimLab = KirimLabDao(_appDatabase),
      _kirimSertifikatEstate = KirimSertifikatEstateDao(_appDatabase);

  static const String _table = 'data_sampel_pupuk';

  final AppDatabase _appDatabase;
  final KirimDariEstateDao _kirimDariEstate;
  final KirimLabDao _kirimLab;
  final KirimSertifikatEstateDao _kirimSertifikatEstate;

  /// Replaces the local snapshot atomically so a failed insert never leaves an
  /// empty table. [regional] null replaces everything.
  Future<void> replaceSnapshot(
    List<DataSampelPupuk> list, {
    int? regional,
  }) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      if (regional == null) {
        await txn.delete(_table);
      } else {
        await txn.delete(_table, where: 'regional = ?', whereArgs: [regional]);
      }
      final batch = txn.batch();
      for (final e in list) {
        batch.insert(
          _table,
          e.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<DataSampelPupuk>> getAll({int? regional}) async {
    final db = await _appDatabase.database;
    final rows = regional != null
        ? await db.query(
            _table,
            where: 'regional = ?',
            whereArgs: [regional],
            orderBy: 'kode_sampel ASC',
          )
        : await db.query(_table, orderBy: 'kode_sampel ASC');
    return rows.map(DataSampelPupuk.fromJson).toList();
  }

  Future<DataSampelPupuk?> getById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return DataSampelPupuk.fromJson(rows.first);
  }

  /// The record plus the latest local row of each activity table (activity
  /// visibility on the detail screen). With [individualKodeSampel] only rows
  /// for that code count and it replaces the record's own kode.
  Future<AktivitasSampelPupuk?> getAktivitas(
    int dataSampelPupukId, {
    String? individualKodeSampel,
  }) async {
    final data = await getById(dataSampelPupukId);
    if (data == null) return null;

    return AktivitasSampelPupuk(
      id: data.id,
      kodeSampel: individualKodeSampel ?? data.kodeSampel ?? '',
      dataSampelPupuk: data,
      kirimDariEstate: await _kirimDariEstate.getLatestForSample(
        dataSampelPupukId,
        kodeSampel: individualKodeSampel,
      ),
      kirimLab: await _kirimLab.getLatestForSample(
        dataSampelPupukId,
        kodeSampel: individualKodeSampel,
      ),
      kirimSertifikatEstate: await _kirimSertifikatEstate.getLatestForSample(
        dataSampelPupukId,
        kodeSampel: individualKodeSampel,
      ),
    );
  }

  /// Kirim Sertifikat candidates: has a certificate number and was not sent yet.
  Future<List<DataSampelPupuk>> getEligibleKirimSertifikat() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _table,
      where:
          "(no_sertifikat IS NOT NULL AND TRIM(no_sertifikat) <> '') AND "
          "(tanggal_kirim_sertifikat_estate IS NULL OR TRIM(tanggal_kirim_sertifikat_estate) = '')",
      orderBy: 'kode_sampel ASC',
    );
    return rows.map(DataSampelPupuk.fromJson).toList();
  }

  Future<int> updateTanggalKirimSertifikatEstate(
    int dataSampelPupukId,
    String isoDateTime, {
    String? rekomendasi,
  }) async {
    final db = await _appDatabase.database;
    return db.update(
      _table,
      {
        'tanggal_kirim_sertifikat_estate': isoDateTime,
        if (rekomendasi != null) 'rekomendasi': rekomendasi,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [dataSampelPupukId],
    );
  }

  /// No. surat from synced data ([fromData]) or the latest local Kirim Lab row.
  Future<String?> resolveNoSurat(
    int dataSampelPupukId, {
    String? fromData,
  }) async {
    final trimmed = fromData?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return _kirimLab.latestNoSurat(dataSampelPupukId);
  }
}
