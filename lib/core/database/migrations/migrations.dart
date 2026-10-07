import 'package:sqflite/sqflite.dart';
import 'migration.dart';
import 'schema.dart';
import 'v2_tracking_column.dart';
import 'v3_pupuk_lab.dart';
import 'v4_pupuk_lab_error_retryable.dart';
import 'v5_form_completion_suggestions.dart';

/// Ordered by version, contiguous from 2. Version 1 is the original schema
/// created by builds that predate this registry.
const List<Migration> kMigrations = [
  MigrationV2TrackingColumn(),
  MigrationV3PupukLab(),
  MigrationV4PupukLabErrorRetryable(),
  MigrationV5FormCompletionSuggestions(),
];

int get kDatabaseVersion => kMigrations.last.version;

Future<void> createDatabase(Database db, int version) async {
  for (final statement in Schema.createStatements) {
    await db.execute(statement);
  }
}

Future<void> upgradeDatabase(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  for (final migration in kMigrations) {
    if (migration.version > oldVersion && migration.version <= newVersion) {
      await migration.up(db);
    }
  }
}
