import '../../constants/app_constants.dart';
import '../app_database.dart';
import '../models/completed_sample.dart';
import '../models/master_lsu.dart';
import '../models/master_sampel.dart';
import '../models/received_sample.dart';
import 'status_table.dart';

/// LSU aggregate: synced master data plus the locally captured terima/selesai
/// rows. Use [received] and [completed] for the upload-status tables.
class LsuDao {
  LsuDao(this._appDatabase)
    : received = ReceivedSampleTable(_appDatabase),
      completed = CompletedSampleTable(_appDatabase);

  final AppDatabase _appDatabase;
  final ReceivedSampleTable received;
  final CompletedSampleTable completed;

  Future<void> insertMasterSampelBatch(List<MasterSampel> sampels) async {
    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final sampel in sampels) {
      batch.insert('master_sampel', sampel.toJson());
    }
    await batch.commit(noResult: true);
  }

  Future<int> clearMasterSampel() async {
    final db = await _appDatabase.database;
    return db.delete('master_sampel');
  }

  Future<void> insertMasterLsuBatch(List<MasterLsu> lsus) async {
    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final lsu in lsus) {
      batch.insert('master_lsu', lsu.toJson());
    }
    await batch.commit(noResult: true);
  }

  Future<MasterLsu?> getMasterLsuById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query('master_lsu', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MasterLsu.fromJson(rows.first);
  }

  Future<int> clearMasterLsu() async {
    final db = await _appDatabase.database;
    return db.delete('master_lsu');
  }
}

class ReceivedSampleTable extends StatusTable<ReceivedSample> {
  ReceivedSampleTable(super.appDatabase)
    : super(
        table: 'received_sample',
        fromJson: ReceivedSample.fromJson,
        toJson: (row) => row.toJson(),
      );

  Future<List<ReceivedSample>> getUploaded() async {
    final db = await appDatabase.database;
    final rows = await db.query(
      table,
      where: 'status = ?',
      whereArgs: [AppConstants.statusUploaded],
      orderBy: 'created_at DESC',
    );
    return rows.map(fromJson).toList();
  }

  /// `data_lsu_id` is unique, so at most one row exists.
  Future<ReceivedSample?> getByDataLsuId(int dataLsuId) async {
    final db = await appDatabase.database;
    final rows = await db.query(
      table,
      where: 'data_lsu_id = ?',
      whereArgs: [dataLsuId],
    );
    if (rows.isEmpty) return null;
    return fromJson(rows.first);
  }
}

class CompletedSampleTable extends StatusTable<CompletedSample> {
  CompletedSampleTable(super.appDatabase)
    : super(
        table: 'completed_sample',
        fromJson: CompletedSample.fromJson,
        toJson: (row) => row.toJson(),
      );

  Future<CompletedSample?> getByDataLsuId(int dataLsuId) async {
    final db = await appDatabase.database;
    final rows = await db.query(
      table,
      where: 'data_lsu_id = ?',
      whereArgs: [dataLsuId],
    );
    if (rows.isEmpty) return null;
    return fromJson(rows.first);
  }
}
