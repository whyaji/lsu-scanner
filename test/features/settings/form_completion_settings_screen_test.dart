import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/database/database_providers.dart';
import 'package:sampletrack/core/database/daos/form_completion_suggestions_dao.dart';
import 'package:sampletrack/core/database/models/form_completion_suggestion.dart';
import 'package:sampletrack/core/theme/app_theme.dart';
import 'package:sampletrack/features/settings/screens/form_completion_settings_screen.dart';
import 'package:sampletrack/widgets/buttons/app_button.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_database.dart';

class _FakeSuggestionsDao extends FormCompletionSuggestionsDao {
  _FakeSuggestionsDao(super.database);

  final List<FormCompletionSuggestion> items = [];
  var _nextId = 1;

  @override
  Future<List<FormCompletionSuggestion>> getAll({
    FormCompletionSuggestionType? type,
  }) async => [
    for (final item in items)
      if (type == null || item.type == type) item,
  ];

  @override
  Future<void> add(FormCompletionSuggestionType type, String value) async {
    items.add(
      FormCompletionSuggestion(
        id: _nextId++,
        type: type,
        value: value,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  testWidgets(
    'saving a form-completion suggestion does not use its controller after disposal',
    (tester) async {
      final database = newTestDatabase();
      final suggestionsDao = _FakeSuggestionsDao(database);
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            formCompletionSuggestionsDaoProvider.overrideWithValue(
              suggestionsDao,
            ),
            formCompletionSuggestionsProvider.overrideWith(
              (ref) async => const [],
            ),
          ],
          child: testApp(
            const FormCompletionSettingsScreen(),
            theme: AppTheme.light,
            scaffold: false,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FormCompletionSettingsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Tambah email'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), 'new@example.com');
      final saveButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Simpan ke saran'),
      );
      saveButton.onPressed?.call();

      // Exercise the bottom-sheet closing animation and the next rebuild.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    },
  );
}
