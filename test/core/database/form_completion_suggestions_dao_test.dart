import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/daos/form_completion_suggestions_dao.dart';
import 'package:sampletrack/core/database/models/form_completion_suggestion.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late FormCompletionSuggestionsDao dao;

  setUp(() {
    database = newTestDatabase();
    dao = FormCompletionSuggestionsDao(database);
  });

  tearDown(() => database.close());

  test('saved values are unique by type and normalized value', () async {
    await dao.saveValues(
      emails: ['Admin@Example.com', 'admin@example.com'],
      whatsappNumbers: ['081234567890', '6281234567890'],
    );

    final rows = await dao.getAll();
    expect(rows, hasLength(2));
    expect(
      rows.map((row) => row.type),
      containsAll([
        FormCompletionSuggestionType.email,
        FormCompletionSuggestionType.whatsapp,
      ]),
    );
  });

  test('values can be filtered and deleted', () async {
    await dao.saveValues(
      emails: ['one@example.com', 'two@example.com'],
      whatsappNumbers: ['6281234567890'],
    );

    final emails = await dao.getAll(type: FormCompletionSuggestionType.email);
    expect(emails, hasLength(2));

    await dao.delete(emails.first.id);
    expect(await dao.values(FormCompletionSuggestionType.email), hasLength(1));
  });
}
