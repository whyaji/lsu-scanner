import 'package:sqflite/sqflite.dart';
import 'migration.dart';
import 'schema.dart';

/// Lets an upload remember that SmartLab rejected a Terima Lab receipt for good,
/// so the same photos are not sent again until the receipt is edited.
class MigrationV4PupukLabErrorRetryable implements Migration {
  const MigrationV4PupukLabErrorRetryable();

  @override
  int get version => 4;

  @override
  Future<void> up(DatabaseExecutor db) async {
    for (final entry in Schema.pupukLabV4Columns.entries) {
      await addColumnIfMissing(db, 'pupuk_lab', entry.key, entry.value);
    }
  }
}
