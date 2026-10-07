import 'package:sqflite/sqflite.dart';
import 'migration.dart';
import 'schema.dart';

/// Pupuk Lab: receipt table, master data cache, and the two sync columns that
/// record who received a sample at the lab. Drops the unused legacy
/// `terima_dari_*` tables.
class MigrationV3PupukLab implements Migration {
  const MigrationV3PupukLab();

  @override
  int get version => 3;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute(Schema.pupukLab);
    await db.execute(Schema.pupukLabMaster);
    for (final entry in Schema.dataSampelPupukV3Columns.entries) {
      await addColumnIfMissing(db, 'data_sampel_pupuk', entry.key, entry.value);
    }
    for (final table in Schema.legacyTablesDroppedInV3) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
  }
}
