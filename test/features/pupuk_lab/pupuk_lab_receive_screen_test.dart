import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/daos/data_sampel_pupuk_dao.dart';
import 'package:sampletrack/core/database/database_providers.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';
import 'package:sampletrack/core/theme/app_theme.dart';
import 'package:sampletrack/features/auth/providers/auth_provider.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_master_repository.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_dao.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_form.dart';
import 'package:sampletrack/features/pupuk_lab/providers/pupuk_lab_providers.dart';
import 'package:sampletrack/features/pupuk_lab/screens/pupuk_lab_receive_screen.dart';

import '../../helpers/pupuk_lab_fixtures.dart';
import '../../helpers/stub_auth.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_database.dart';

PupukLabMasterSnapshot snapshot({bool stale = false}) => PupukLabMasterSnapshot(
  master: sampleMaster(),
  syncedAt: DateTime(2026, 10, 5, 8, 30),
  isStale: stale,
);

String _stepTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('pupukLabStepTitle'))).data!;

/// Lets real async work (SQLite on its own isolate) finish between frames.
/// `pumpAndSettle` is not used: a spinner on screen keeps it pumping forever.
Future<void> pumpFor(WidgetTester tester, {int rounds = 14}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Opens the screen from a button, so back navigation has somewhere to go.
class _Host extends StatelessWidget {
  const _Host({this.editing});

  final PupukLab? editing;

  @override
  Widget build(BuildContext context) => Center(
    child: ElevatedButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PupukLabReceiveScreen(editing: editing),
        ),
      ),
      child: const Text('Buka'),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    await db.database;
  });
  tearDown(() => db.close());

  Future<void> pumpScreen(
    WidgetTester tester, {
    PupukLabMasterSnapshot? master,
    PupukLab? editing,
    ThemeData? theme,
    double scale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 640 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authProvider.overrideWith((ref) => StubAuthNotifier()),
          pupukLabMasterProvider.overrideWith((ref) async => master),
        ],
        child: testApp(
          _Host(editing: editing),
          theme: theme,
          textScale: scale,
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await pumpFor(tester);
  }

  group('first step', () {
    for (final entry in {
      'light': AppTheme.light,
      'dark': AppTheme.dark,
    }.entries) {
      testWidgets(
        'renders without overflow in ${entry.key} at text scale 1.3',
        (tester) async {
          await pumpScreen(
            tester,
            master: snapshot(),
            theme: entry.value,
            scale: 1.3,
          );

          expect(find.text('Langkah 1 dari 5'), findsNothing);
          expect(_stepTitle(tester), 'Sampel');
          expect(find.text('Belum ada sampel'), findsOneWidget);
          expect(find.text('Pindai label'), findsOneWidget);
          expect(find.text('Ketik kode'), findsOneWidget);
          expect(find.text('Lanjut'), findsOneWidget);
          expect(find.text('Kembali'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('continuing without samples shows what is missing', (
      tester,
    ) async {
      await pumpScreen(tester, master: snapshot());

      await tester.tap(find.text('Lanjut'));
      await pumpFor(tester);

      expect(find.text('Langkah 1 dari 5'), findsNothing);
      expect(_stepTitle(tester), 'Sampel');
      expect(find.textContaining('perlu diperbaiki'), findsOneWidget);
      expect(find.text('No. surat wajib diisi.'), findsOneWidget);
    });

    testWidgets('a manual code joins the list and is marked Manual', (
      tester,
    ) async {
      await pumpScreen(tester, master: snapshot());

      await tester.tap(find.text('Ketik kode'));
      await pumpFor(tester);
      await tester.enterText(find.byType(TextField).last, 'MANUAL-77');
      await tester.tap(find.text('Tambahkan sampel'));
      await pumpFor(tester);

      expect(find.text('MANUAL-77'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Sampel (1)'), findsOneWidget);
      expect(find.text('Belum ada sampel'), findsNothing);
    });

    testWidgets('a manual code that SampleTrack already knows is refused', (
      tester,
    ) async {
      await pumpScreen(tester, master: snapshot());
      await tester.runAsync(
        () => DataSampelPupukDao(db).replaceSnapshot([
          DataSampelPupuk(id: 9, kodeSampel: 'NBE/NPK/ABCD/01'),
        ]),
      );

      await tester.tap(find.text('Ketik kode'));
      await pumpFor(tester);
      await tester.enterText(find.byType(TextField).last, 'NBE/NPK/B/01');
      await tester.tap(find.text('Tambahkan sampel'));
      await pumpFor(tester);

      expect(
        find.textContaining('sudah terdaftar di SampleTrack'),
        findsOneWidget,
      );
      expect(find.text('Sampel (1)'), findsNothing);
    });

    testWidgets('removing a sample asks first', (tester) async {
      await pumpScreen(tester, master: snapshot());
      await tester.tap(find.text('Ketik kode'));
      await pumpFor(tester);
      await tester.enterText(find.byType(TextField).last, 'MANUAL-77');
      await tester.tap(find.text('Tambahkan sampel'));
      await pumpFor(tester);

      await tester.tap(find.byTooltip('Hapus sampel MANUAL-77'));
      await pumpFor(tester);
      expect(find.text('Hapus MANUAL-77?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await pumpFor(tester);
      expect(find.text('MANUAL-77'), findsOneWidget);

      await tester.tap(find.byTooltip('Hapus sampel MANUAL-77'));
      await pumpFor(tester);
      await tester.tap(find.text('Hapus sampel'));
      await pumpFor(tester);
      expect(find.text('MANUAL-77'), findsNothing);
      expect(find.text('Belum ada sampel'), findsOneWidget);
    });
  });

  group('master data', () {
    testWidgets('without a master the form does not open and offers a sync', (
      tester,
    ) async {
      await pumpScreen(tester, master: null);

      expect(find.text('Data master SmartLab belum ada'), findsOneWidget);
      expect(find.text('Sinkronkan sekarang'), findsOneWidget);
      expect(find.text('Lanjut'), findsNothing);
    });

    testWidgets('a stale master warns but keeps the form usable', (
      tester,
    ) async {
      await pumpScreen(tester, master: snapshot(stale: true));

      expect(find.text('Data master belum diperbarui'), findsOneWidget);
      expect(find.textContaining('5 Oktober 2026'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });
  });

  group('leaving', () {
    testWidgets('an untouched form closes without asking', (tester) async {
      await pumpScreen(tester, master: snapshot());

      await tester.tap(find.byType(BackButton));
      await pumpFor(tester);

      expect(find.text('Buka'), findsOneWidget);
    });

    testWidgets('a changed form asks, and can be kept', (tester) async {
      await pumpScreen(tester, master: snapshot());
      await tester.enterText(find.byType(TextField).first, 'SRS/9');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await pumpFor(tester);
      expect(find.text('Buang isian ini?'), findsOneWidget);

      await tester.tap(find.text('Lanjut mengisi'));
      await pumpFor(tester);
      expect(find.text('Langkah 1 dari 5'), findsNothing);
      expect(_stepTitle(tester), 'Sampel');

      await tester.tap(find.byType(BackButton));
      await pumpFor(tester);
      await tester.tap(find.text('Buang isian'));
      await pumpFor(tester);
      expect(find.text('Buka'), findsOneWidget);
    });
  });

  group('editing a saved receipt', () {
    testWidgets('walks the five steps and saves the change on the device', (
      tester,
    ) async {
      final dao = PupukLabDao(db);
      final id = await tester.runAsync(
        () => dao.insert(
          samplePupukLab(
            clientUuid: 'uuid-edit',
            fotoPaths: const ['/tmp/terima-lab.jpg'],
          ),
        ),
      );
      final stored = (await tester.runAsync(() => dao.getById(id!)))!;

      await pumpScreen(tester, master: snapshot(), editing: stored);
      await pumpFor(tester);

      expect(find.text('Ubah penerimaan'), findsOneWidget);
      expect(find.text('Sampel (3)'), findsOneWidget);
      expect(find.text('MANUAL-9'), findsOneWidget);

      for (var step = 2; step <= 5; step++) {
        await tester.tap(find.text('Lanjut'));
        await pumpFor(tester);
        expect(find.text('Langkah $step dari 5'), findsNothing);
        expect(
          _stepTitle(tester),
          const [
            'Sampel',
            'Informasi',
            'Pengirim',
            'Parameter',
            'Ringkasan',
          ][step - 1],
        );
      }
      expect(find.text('SRS/001'), findsOneWidget);
      expect(find.text('Simpan penerimaan'), findsOneWidget);
      final primary = tester.getCenter(find.text('Simpan penerimaan'));
      final secondary = tester.getCenter(find.text('Kembali'));
      expect((primary.dy - secondary.dy).abs(), lessThan(12));
      expect(secondary.dx, lessThan(primary.dx));

      await tester.enterText(
        find.byType(TextFormField).last,
        'Segel utuh, dibawa kurir',
      );
      await tester.tap(find.text('Simpan penerimaan'));
      await pumpFor(tester);

      expect(find.text('Penerimaan tersimpan'), findsOneWidget);
      await tester.tap(find.text('Nanti saja'));
      await pumpFor(tester);

      final after = (await tester.runAsync(() => dao.getById(id!)))!;
      expect(after.clientUuid, 'uuid-edit');
      expect(after.form.catatan, 'Segel utuh, dibawa kurir');
      expect(after.status, 'not_uploaded');
      expect(find.text('Buka'), findsOneWidget);
    });

    testWidgets('a rejected receipt reopens, can be fixed, and is sent again', (
      tester,
    ) async {
      final dao = PupukLabDao(db);
      final id = (await tester.runAsync(
        () => dao.insert(
          samplePupukLab(
            clientUuid: 'uuid-bad',
            fotoPaths: const ['/tmp/terima-lab.jpg'],
          ),
        ),
      ))!;
      await tester.runAsync(
        () => dao.markFailed(id, 'Parameter tidak valid', retryable: false),
      );
      final stored = (await tester.runAsync(() => dao.getById(id)))!;
      expect(stored.needsEdit, isTrue);

      await pumpScreen(tester, master: snapshot(), editing: stored);
      await pumpFor(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Lanjut'));
        await pumpFor(tester);
      }
      await tester.tap(find.text('Simpan penerimaan'));
      await pumpFor(tester);
      await tester.tap(find.text('Nanti saja'));
      await pumpFor(tester);

      final after = (await tester.runAsync(() => dao.getById(id)))!;
      expect(after.needsEdit, isFalse);
      expect(after.status, 'not_uploaded');
      expect(after.errorMessage, isNull);
    });

    testWidgets('an invalid receipt cannot be saved and points to the step', (
      tester,
    ) async {
      final dao = PupukLabDao(db);
      final broken = samplePupukLab(
        clientUuid: 'uuid-broken',
        fotoPaths: const ['/tmp/terima-lab.jpg'],
      );
      final id = (await tester.runAsync(() => dao.insert(broken)))!;
      final stored = (await tester.runAsync(() => dao.getById(id)))!;
      // An estimasi before the receipt date is the kind of change a user makes.
      final badForm = stored.form.toJson()..['estimasiKupa'] = '2026-01-01';
      final edited = PupukLab(
        id: id,
        clientUuid: stored.clientUuid,
        noSurat: stored.noSurat,
        samples: stored.samples,
        form: PupukLabForm.fromJson(badForm),
        createdAt: stored.createdAt,
      );

      await pumpScreen(tester, master: snapshot(), editing: edited);
      await pumpFor(tester);
      await tester.tap(find.text('Lanjut'));
      await pumpFor(tester);
      expect(_stepTitle(tester), 'Informasi');

      await tester.tap(find.text('Lanjut'));
      await pumpFor(tester);

      expect(_stepTitle(tester), 'Informasi');
      expect(find.textContaining('perlu diperbaiki'), findsOneWidget);
      expect(
        find.text('Estimasi KUPA tidak boleh sebelum tanggal terima.'),
        findsWidgets,
      );
    });
  });
}
