import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

class PreferencesDao {
  PreferencesDao(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> set(String key, String value) async {
    final db = await _appDatabase.database;
    await db.insert('user_preferences', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> get(String key) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> delete(String key) async {
    final db = await _appDatabase.database;
    await db.delete('user_preferences', where: 'key = ?', whereArgs: [key]);
  }
}
