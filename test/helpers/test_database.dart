import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sampletrack/core/database/app_database.dart';

bool _ffiReady = false;

/// Fresh in-memory database that runs the real `onCreate`.
AppDatabase newTestDatabase() {
  if (!_ffiReady) {
    sqfliteFfiInit();
    _ffiReady = true;
  }
  return AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
}
