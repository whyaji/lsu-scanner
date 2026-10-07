import 'package:sqflite/sqflite.dart';
import 'migration.dart';

class MigrationV2TrackingColumn implements Migration {
  const MigrationV2TrackingColumn();

  @override
  int get version => 2;

  @override
  Future<void> up(DatabaseExecutor db) => addColumnIfMissing(
    db,
    'data_sampel_pupuk',
    'tracking_sampel_pupuk',
    'TEXT',
  );
}
