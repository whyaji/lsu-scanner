import '../../constants/app_constants.dart';
import '../app_database.dart';

/// Shared access for tables of locally created rows that wait to be uploaded
/// (`status` = not_uploaded | uploaded | error, newest first).
abstract class StatusTable<T> {
  StatusTable(
    this.appDatabase, {
    required this.table,
    required this.fromJson,
    required this.toJson,
  });

  final AppDatabase appDatabase;
  final String table;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T row) toJson;

  /// Never inserts an explicit id: SQLite assigns it.
  Future<int> insert(T row) async {
    final db = await appDatabase.database;
    final map = toJson(row)..remove('id');
    return db.insert(table, map);
  }

  /// Rows the upload still has to send: not uploaded yet, or failed before.
  Future<List<T>> getPending() async {
    final db = await appDatabase.database;
    final rows = await db.query(
      table,
      where: 'status IN (?, ?)',
      whereArgs: [AppConstants.statusNotUploaded, AppConstants.statusError],
      orderBy: 'created_at DESC',
    );
    return rows.map(fromJson).toList();
  }

  Future<List<T>> getAll() async {
    final db = await appDatabase.database;
    final rows = await db.query(table, orderBy: 'created_at DESC');
    return rows.map(fromJson).toList();
  }

  Future<T?> getById(int id) async {
    final db = await appDatabase.database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return fromJson(rows.first);
  }

  Future<int> delete(int id) async {
    final db = await appDatabase.database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateStatus(
    int id,
    String status, {
    String? errorMessage,
  }) async {
    final db = await appDatabase.database;
    return db.update(
      table,
      {
        'status': status,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Activity rows linked to a `data_sampel_pupuk` record.
abstract class SampelActivityTable<T> extends StatusTable<T> {
  SampelActivityTable(
    super.appDatabase, {
    required super.table,
    required super.fromJson,
    required super.toJson,
  });

  /// Latest local row for the sample; when [kodeSampel] is set only rows for
  /// that individual code match (batch records hold many codes).
  Future<T?> getLatestForSample(
    int dataSampelPupukId, {
    String? kodeSampel,
  }) async {
    final db = await appDatabase.database;
    final rows = await db.query(
      table,
      where: kodeSampel != null
          ? 'data_sampel_pupuk_id = ? AND kode_sampel = ?'
          : 'data_sampel_pupuk_id = ?',
      whereArgs: kodeSampel != null
          ? [dataSampelPupukId, kodeSampel]
          : [dataSampelPupukId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return fromJson(rows.first);
  }
}
