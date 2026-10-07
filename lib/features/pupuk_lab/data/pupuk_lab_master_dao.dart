import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/pupuk_lab_master.dart';

class StoredPupukLabMaster {
  const StoredPupukLabMaster({required this.master, required this.syncedAt});

  final PupukLabMaster master;

  /// When this device last received the master from the backend.
  final DateTime syncedAt;
}

/// Single-row cache of the SmartLab master data (`pupuk_lab_master`, key
/// `master`).
class PupukLabMasterDao {
  PupukLabMasterDao(this._appDatabase);

  static const String _table = 'pupuk_lab_master';
  static const String _key = 'master';

  final AppDatabase _appDatabase;

  Future<void> save(PupukLabMaster master, {DateTime? syncedAt}) async {
    final db = await _appDatabase.database;
    await db.insert(_table, {
      'key': _key,
      'json': jsonEncode(master.toJson()),
      'version': master.version,
      'synced_at': (syncedAt ?? DateTime.now()).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<StoredPupukLabMaster?> load() async {
    final db = await _appDatabase.database;
    final rows = await db.query(_table, where: 'key = ?', whereArgs: [_key]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return StoredPupukLabMaster(
      master: PupukLabMaster.fromApiJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      ),
      syncedAt: DateTime.tryParse(row['synced_at'] as String) ?? DateTime.now(),
    );
  }

  Future<void> clear() async {
    final db = await _appDatabase.database;
    await db.delete(_table);
  }
}
