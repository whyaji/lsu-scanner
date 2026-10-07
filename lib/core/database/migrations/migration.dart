import 'package:sqflite/sqflite.dart';

/// One schema step, applied when upgrading from `version - 1` to `version`.
///
/// sqflite runs `onUpgrade` inside a transaction, so a failing step rolls the
/// whole upgrade back and the database stays on the old version.
abstract interface class Migration {
  int get version;

  Future<void> up(DatabaseExecutor db);
}

Future<bool> columnExists(
  DatabaseExecutor db,
  String table,
  String column,
) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return info.any((row) => row['name'] == column);
}

/// `ALTER TABLE ADD COLUMN` that tolerates databases where an earlier build
/// already added the column.
Future<void> addColumnIfMissing(
  DatabaseExecutor db,
  String table,
  String column,
  String type,
) async {
  if (await columnExists(db, table, column)) return;
  await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
}
