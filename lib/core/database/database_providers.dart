import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'daos/data_sampel_pupuk_dao.dart';
import 'daos/form_completion_suggestions_dao.dart';
import 'daos/kirim_dari_estate_dao.dart';
import 'daos/kirim_lab_dao.dart';
import 'daos/kirim_sertifikat_estate_dao.dart';
import 'daos/lsu_dao.dart';
import 'daos/preferences_dao.dart';
import 'models/form_completion_suggestion.dart';

/// One connection for the app. Tests override it with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final lsuDaoProvider = Provider<LsuDao>(
  (ref) => LsuDao(ref.watch(appDatabaseProvider)),
);

final dataSampelPupukDaoProvider = Provider<DataSampelPupukDao>(
  (ref) => DataSampelPupukDao(ref.watch(appDatabaseProvider)),
);

final kirimDariEstateDaoProvider = Provider<KirimDariEstateDao>(
  (ref) => KirimDariEstateDao(ref.watch(appDatabaseProvider)),
);

final kirimLabDaoProvider = Provider<KirimLabDao>(
  (ref) => KirimLabDao(ref.watch(appDatabaseProvider)),
);

final kirimSertifikatEstateDaoProvider = Provider<KirimSertifikatEstateDao>(
  (ref) => KirimSertifikatEstateDao(ref.watch(appDatabaseProvider)),
);

final preferencesDaoProvider = Provider<PreferencesDao>(
  (ref) => PreferencesDao(ref.watch(appDatabaseProvider)),
);

final formCompletionSuggestionsDaoProvider =
    Provider<FormCompletionSuggestionsDao>(
      (ref) => FormCompletionSuggestionsDao(ref.watch(appDatabaseProvider)),
    );

final formCompletionSuggestionsProvider =
    FutureProvider.autoDispose<List<FormCompletionSuggestion>>(
      (ref) => ref.watch(formCompletionSuggestionsDaoProvider).getAll(),
    );
