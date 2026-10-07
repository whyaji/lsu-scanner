import 'package:sqflite/sqflite.dart';

import 'migration.dart';
import 'schema.dart';

/// Stores reusable email and WhatsApp values entered in saved forms.
class MigrationV5FormCompletionSuggestions implements Migration {
  const MigrationV5FormCompletionSuggestions();

  @override
  int get version => 5;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute(Schema.formCompletionSuggestions);
  }
}
