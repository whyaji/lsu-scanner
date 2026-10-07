import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/daos/status_table.dart';
import '../models/pupuk_lab.dart';

/// Local Terima Lab receipts. Inherits pending/all/byId/delete/updateStatus.
class PupukLabDao extends StatusTable<PupukLab> {
  PupukLabDao(super.appDatabase)
    : super(
        table: 'pupuk_lab',
        fromJson: PupukLab.fromJson,
        toJson: (row) => row.toJson(),
      );

  /// Saves edits to a receipt that is not uploaded yet. The row goes back to
  /// `not_uploaded` so the next upload retries it; `client_uuid` is untouched.
  Future<int> updateDraft(PupukLab row) async {
    final id = row.id;
    if (id == null) throw ArgumentError('updateDraft needs a saved row');
    final db = await appDatabase.database;
    final map = row.toJson()
      ..remove('id')
      ..remove('client_uuid')
      ..remove('created_at')
      ..['status'] = AppConstants.statusNotUploaded
      ..['error_message'] = null
      ..['error_retryable'] = 1
      ..['updated_at'] = DateTime.now().toIso8601String();
    return db.update(table, map, where: 'id = ?', whereArgs: [id]);
  }

  /// Records a failed upload. A non retryable failure keeps the row out of
  /// uploads until [updateDraft] resets it.
  Future<int> markFailed(
    int id,
    String message, {
    required bool retryable,
  }) async {
    final db = await appDatabase.database;
    return db.update(
      table,
      {
        'status': AppConstants.statusError,
        'error_message': message,
        'error_retryable': retryable ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markUploaded(
    int id, {
    required String kodeTrack,
    required String nomorLab,
    required int nomorKupa,
  }) async {
    final db = await appDatabase.database;
    return db.update(
      table,
      {
        'status': AppConstants.statusUploaded,
        'error_message': null,
        'error_retryable': 1,
        'kode_track': kodeTrack,
        'nomor_lab': nomorLab,
        'nomor_kupa': nomorKupa,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Every sample code held by a local receipt, uploaded or not. Until the
  /// next sync marks the record as received, these must not be offered again.
  /// Pass [excludingId] when editing a receipt so it keeps its own codes.
  Future<Set<String>> getReservedKodeSampel({int? excludingId}) async {
    final db = await appDatabase.database;
    final rows = await db.query(
      table,
      columns: ['samples_json'],
      where: excludingId == null ? null : 'id <> ?',
      whereArgs: excludingId == null ? null : [excludingId],
    );
    final kodes = <String>{};
    for (final row in rows) {
      final samples = jsonDecode(row['samples_json'] as String) as List;
      for (final sample in samples) {
        kodes.add((sample as Map<String, dynamic>)['kodeSampel'] as String);
      }
    }
    return kodes;
  }
}
