import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import 'migrations/migrations.dart';

/// Owns the SQLite connection and schema versioning. Data access lives in the
/// DAOs under `daos/`, which receive this object and call [database].
class AppDatabase {
  /// [factory] and [path] exist for tests (sqflite_common_ffi, in-memory).
  /// Production uses the platform factory and `sampletrack.db`.
  AppDatabase({DatabaseFactory? factory, String? path})
    : _factory = factory ?? databaseFactory,
      _path = path;

  final DatabaseFactory _factory;
  final String? _path;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final path =
        _path ??
        join(await _factory.getDatabasesPath(), AppConstants.databaseName);
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: kDatabaseVersion,
        onCreate: createDatabase,
        onUpgrade: upgradeDatabase,
      ),
    );
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    _opening = null;
    await (await opening).close();
  }
}
