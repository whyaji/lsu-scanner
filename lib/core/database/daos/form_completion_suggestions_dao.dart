import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../models/form_completion_suggestion.dart';

class FormCompletionSuggestionsDao {
  FormCompletionSuggestionsDao(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<FormCompletionSuggestion>> getAll({
    FormCompletionSuggestionType? type,
  }) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'form_completion_suggestions',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type.value],
      orderBy: 'updated_at DESC, id DESC',
    );
    return rows.map(FormCompletionSuggestion.fromRow).toList();
  }

  Future<List<String>> values(FormCompletionSuggestionType type) async {
    final rows = await getAll(type: type);
    return rows.map((suggestion) => suggestion.value).toList();
  }

  Future<void> saveValues({
    Iterable<String> emails = const [],
    Iterable<String> whatsappNumbers = const [],
  }) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await _saveValues(
        txn,
        type: FormCompletionSuggestionType.email,
        values: emails,
      );
      await _saveValues(
        txn,
        type: FormCompletionSuggestionType.whatsapp,
        values: whatsappNumbers,
      );
    });
  }

  Future<void> add(FormCompletionSuggestionType type, String value) async {
    await saveValues(
      emails: type == FormCompletionSuggestionType.email ? [value] : const [],
      whatsappNumbers: type == FormCompletionSuggestionType.whatsapp
          ? [value]
          : const [],
    );
  }

  Future<void> delete(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      'form_completion_suggestions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _saveValues(
    DatabaseExecutor db, {
    required FormCompletionSuggestionType type,
    required Iterable<String> values,
  }) async {
    final now = DateTime.now().toIso8601String();
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final normalized = type == FormCompletionSuggestionType.email
          ? value.toLowerCase()
          : _normalizePhone(value);
      if (normalized.isEmpty) continue;
      final storedValue = type == FormCompletionSuggestionType.whatsapp
          ? normalized
          : value;

      await db.insert('form_completion_suggestions', {
        'type': type.value,
        'value': storedValue,
        'normalized_value': normalized,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.update(
        'form_completion_suggestions',
        {'value': storedValue, 'updated_at': now},
        where: 'type = ? AND normalized_value = ?',
        whereArgs: [type.value, normalized],
      );
    }
  }

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('08')) digits = '628${digits.substring(2)}';
    return digits;
  }
}
