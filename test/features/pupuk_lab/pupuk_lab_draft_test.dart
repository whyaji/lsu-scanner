import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/daos/data_sampel_pupuk_dao.dart';
import 'package:sampletrack/core/database/database_providers.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/form_completion_suggestion.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_scan_resolver.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_contact.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_draft.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_master.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_sample.dart';
import 'package:sampletrack/features/pupuk_lab/providers/pupuk_lab_draft_notifier.dart';
import 'package:sampletrack/features/pupuk_lab/providers/pupuk_lab_providers.dart';

import '../../helpers/pupuk_lab_fixtures.dart';
import '../../helpers/test_database.dart';

PupukLabMaster singleJenisMaster() {
  final json = masterApiJson();
  json['jenisSampel'] = [(json['jenisSampel'] as List).first];
  return PupukLabMaster.fromApiJson(json);
}

PupukLabDraftSample scanned(int id, String kode, {String? jenis}) =>
    PupukLabDraftSample(
      sample: PupukLabSample(dataSampelPupukId: id, kodeSampel: kode),
      supplier: 'PT Pupuk',
      jenisPupuk: jenis,
    );

/// A draft where every required field is filled and valid for [sampleMaster].
PupukLabDraft completeDraft(PupukLabMaster master) {
  var draft = PupukLabDraft.create(
    master: master,
    penerima: 'Rina Lab',
    now: DateTime(2026, 10, 6, 9),
    samples: [scanned(5, 'W-001'), scanned(6, 'W-002')],
    noSurat: 'SRS/001',
  ).withJenis(master, 1);
  draft = draft.copyWith(
    jenisPupuk: 'NPK 15-15-15',
    statusPengerjaan: 3,
    estimasiKupa: DateTime(2026, 10, 20),
    kemasanSampel: 'Plastik klip',
    kondisiSampel: 'Normal',
    tujuan: 'Analisis kadar hara',
    namaPengirim: 'Andi Saputra',
    departemen: 'Agronomi',
    emailTo: const ['pelanggan@example.com'],
    parameters: const [
      PupukLabParameterDraft(
        key: 1,
        parameterId: 10,
        totalSample: 2,
        kodeSampel: ['W-001', 'W-002'],
      ),
    ],
    fotoPaths: const ['/tmp/terima-lab.jpg'],
  );
  return draft;
}

void main() {
  group('PupukLabDraft.create', () {
    test('takes defaults from the master and leaves kondisi to the user', () {
      final draft = PupukLabDraft.create(
        master: sampleMaster(),
        penerima: 'Rina Lab',
        now: DateTime(2026, 10, 6, 9),
      );

      expect(draft.asalSampel, 'Internal');
      expect(draft.skalaPrioritas, 'Normal');
      expect(draft.kondisiSampel, isEmpty);
      expect(draft.penerimaSampel, 'Rina Lab');
      expect(draft.emailCc, ['cs.labcbi@citraborneo.co.id']);
      expect(draft.jenisSampelId, isNull, reason: 'two jenis: user chooses');
      expect(draft.dirty, isFalse);
      expect(draft.started, isTrue);
    });

    test(
      'a single jenis is preselected with its staff and document defaults',
      () {
        final draft = PupukLabDraft.create(
          master: singleJenisMaster(),
          penerima: 'Rina Lab',
        );

        expect(draft.jenisSampelId, 1);
        expect(draft.penyelia, 'Budi');
        expect(draft.petugasPreperasi, 'Sari');
        expect(draft.noDocument, 'KUPA-01');
        expect(draft.noDocumentIdentitas, 'ID-01');
        expect(draft.namaFormulir, contains('Pupuk'));
        expect(
          draft.statusPengerjaan,
          isNull,
          reason: 'jenis 1 has two usable statuses',
        );
        expect(draft.dirty, isFalse);
      },
    );

    test(
      'receipt date follows the memo: a memo at noon or later waits a day',
      () {
        final morning = PupukLabDraft.create(
          master: sampleMaster(),
          penerima: 'x',
          now: DateTime(2026, 10, 6, 9),
        );
        final afternoon = PupukLabDraft.create(
          master: sampleMaster(),
          penerima: 'x',
          now: DateTime(2026, 10, 6, 13),
        );

        expect(morning.tanggalTerima, DateTime(2026, 10, 6));
        expect(afternoon.tanggalTerima, DateTime(2026, 10, 7));
      },
    );
  });

  group('withJenis', () {
    test(
      'preselects a single status and drops parameters of the old jenis',
      () {
        final master = sampleMaster();
        final draft = completeDraft(master).withJenis(master, 2);

        expect(draft.jenisSampelId, 2);
        expect(draft.statusPengerjaan, 2, reason: 'jenis 2 only allows id 2');
        expect(draft.parameters, isEmpty);
        expect(draft.penyelia, isEmpty);
      },
    );
  });

  group('validate', () {
    test('a complete draft is valid', () {
      final master = sampleMaster();
      expect(completeDraft(master).validate(master).errors, isEmpty);
    });

    test('untouched pickers say what to do', () {
      final master = sampleMaster();
      final draft = PupukLabDraft.create(
        master: master,
        penerima: '',
        now: DateTime(2026, 10, 6, 9),
      );

      final errors = draft.validate(master).errors;

      expect(errors['jenisSampelId'], 'Pilih jenis komoditas.');
      expect(errors['statusPengerjaan'], 'Pilih status pengerjaan.');
      expect(errors['kondisiSampel'], 'Pilih kondisi sampel.');
      expect(errors['estimasiKupa'], 'Isi estimasi KUPA.');
      expect(errors['namaPengirim'], 'Nama pengirim wajib diisi.');
      expect(errors['penerimaSampel'], 'Penerima sampel wajib diisi.');
      expect(errors['samples'], isNotNull);
      expect(errors['noSurat'], 'No. surat wajib diisi.');
      expect(errors['parameters'], 'Pilih minimal 1 parameter uji.');
    });

    test('a parameter row without a parameter is reported on that row', () {
      final master = sampleMaster();
      final draft = completeDraft(master).copyWith(
        parameters: const [
          PupukLabParameterDraft(key: 1, kodeSampel: ['W-001']),
        ],
      );

      expect(
        draft.validate(master).errors['parameters.0.parameterId'],
        'Pilih parameter.',
      );
    });

    test('errors are grouped by the step that shows the field', () {
      final master = sampleMaster();
      final draft = completeDraft(master).copyWith(
        namaPengirim: '',
        tujuan: '',
        estimasiKupa: DateTime(2026, 1, 1),
        parameters: const [],
      );

      expect(draft.errorsOf(PupukLabStep.samples, master), isEmpty);
      expect(
        draft.errorsOf(PupukLabStep.info, master).keys,
        containsAll(['tujuan', 'estimasiKupa']),
      );
      expect(
        draft.errorsOf(PupukLabStep.contact, master).keys,
        contains('namaPengirim'),
      );
      expect(
        draft.errorsOf(PupukLabStep.parameters, master).keys,
        contains('parameters'),
      );
      expect(draft.errorsOf(PupukLabStep.review, master), isEmpty);
    });
  });

  group('pupukLabStepOfError', () {
    test('maps every field family to a step', () {
      expect(pupukLabStepOfError('samples'), PupukLabStep.samples);
      expect(pupukLabStepOfError('noSurat'), PupukLabStep.samples);
      expect(pupukLabStepOfError('tanggalTerima'), PupukLabStep.info);
      expect(pupukLabStepOfError('emailTo'), PupukLabStep.contact);
      expect(pupukLabStepOfError('diskon'), PupukLabStep.contact);
      expect(
        pupukLabStepOfError('parameters.2.kodeSampel'),
        PupukLabStep.parameters,
      );
      expect(pupukLabStepOfError('fotoPaths'), PupukLabStep.review);
    });
  });

  group('toReceipt', () {
    test('a new receipt gets the given uuid and the form of the draft', () {
      final master = sampleMaster();
      final receipt = completeDraft(
        master,
      ).toReceipt(newClientUuid: 'uuid-new', now: DateTime(2026, 10, 6, 10));

      expect(receipt.clientUuid, 'uuid-new');
      expect(receipt.id, isNull);
      expect(receipt.noSurat, 'SRS/001');
      expect(receipt.form.tanggalTerima, '2026-10-06');
      expect(receipt.form.estimasiKupa, '2026-10-20');
      expect(receipt.kodeSampel, ['W-001', 'W-002']);
      expect(receipt.form.parameters.single.parameterId, 10);
    });

    test('an edited receipt keeps its uuid, id and creation time', () {
      final master = sampleMaster();
      final stored = samplePupukLab(
        id: 4,
        clientUuid: 'uuid-old',
        fotoPaths: const ['/tmp/terima-lab.jpg'],
      );
      final draft = PupukLabDraft.fromReceipt(
        receipt: stored,
        samples: [
          for (final s in stored.samples) PupukLabDraftSample(sample: s),
        ],
      );

      final receipt = draft.toReceipt(newClientUuid: 'ignored');

      expect(receipt.id, 4);
      expect(receipt.clientUuid, 'uuid-old');
      expect(receipt.createdAt, stored.createdAt);
      expect(draft.validate(master).errors, isEmpty);
    });

    test('fromReceipt restores the form so it round trips', () {
      final stored = samplePupukLab(
        id: 1,
        fotoPaths: const ['/tmp/terima-lab.jpg'],
      );
      final draft = PupukLabDraft.fromReceipt(
        receipt: stored,
        samples: [
          for (final s in stored.samples) PupukLabDraftSample(sample: s),
        ],
      );

      expect(
        jsonEncode(draft.toForm().toJson()),
        jsonEncode(stored.form.toJson()),
      );
      expect(draft.tanggalTerimaEdited, isTrue);
    });
  });

  group('normalizeWaPhone', () {
    test('follows the SmartLab rule', () {
      expect(normalizeWaPhone('0812-3456-7890'), '6281234567890');
      expect(normalizeWaPhone('+62 812 3456 7890'), '6281234567890');
      expect(normalizeWaPhone('6281234567890'), '6281234567890');
      expect(normalizeWaPhone('0211234567'), isNull);
      expect(normalizeWaPhone('08123'), isNull);
      expect(normalizeWaPhone('abc'), isNull);
      expect(normalizeWaPhone('0812345678901234567'), isNull);
    });
  });

  group('PupukLabDraftNotifier', () {
    late AppDatabase db;
    late ProviderContainer container;
    late PupukLabDraftNotifier notifier;

    PupukLabDraft read() => container.read(pupukLabDraftProvider);

    setUp(() {
      db = newTestDatabase();
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      container.listen(pupukLabDraftProvider, (previous, next) {});
      notifier = container.read(pupukLabDraftProvider.notifier)
        ..start(
          PupukLabDraft.create(
            master: sampleMaster(),
            penerima: 'Rina Lab',
            now: DateTime(2026, 10, 6, 9),
          ),
        );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'the first scanned sample sets no. surat and jenis pupuk, later ones do not',
      () {
        notifier.addScanned(
          scanned(5, 'W-001', jenis: 'NPK 13'),
          noSurat: 'SRS/001',
        );
        notifier.addScanned(
          scanned(6, 'W-002', jenis: 'Urea'),
          noSurat: 'SRS/001',
        );

        expect(read().noSurat, 'SRS/001');
        expect(read().jenisPupuk, 'NPK 13');
        expect(read().kodes, ['W-001', 'W-002']);
        expect(read().dirty, isTrue);
      },
    );

    test('a scanned code is added only once', () {
      notifier.addScanned(scanned(5, 'W-001'));
      notifier.addScanned(scanned(5, 'W-001'));

      expect(read().samples, hasLength(1));
    });

    test('a typed no. surat is not replaced by a scan', () {
      notifier.patch((d) => d.copyWith(noSurat: 'MANUAL/9'));
      notifier.addScanned(scanned(5, 'W-001'), noSurat: 'SRS/001');

      expect(read().noSurat, 'MANUAL/9');
    });

    test('manual codes are sanitized, unique and length checked', () async {
      expect(await notifier.addManual('  MAN-1 '), PupukLabManualResult.added);
      expect(await notifier.addManual('MAN-1'), PupukLabManualResult.duplicate);
      expect(
        await notifier.addManual("M'A\$N-1"),
        PupukLabManualResult.duplicate,
      );
      expect(await notifier.addManual(''), PupukLabManualResult.empty);
      expect(await notifier.addManual("''"), PupukLabManualResult.empty);
      expect(await notifier.addManual('A'), PupukLabManualResult.tooShort);
      expect(
        await notifier.addManual('X' * (kPupukLabKodeMax + 1)),
        PupukLabManualResult.tooLong,
      );

      expect(read().samples.single.isManual, isTrue);
      expect(read().samples.single.sample.dataSampelPupukId, isNull);
    });

    test(
      'a manual code that is already a SampleTrack sample is refused',
      () async {
        await DataSampelPupukDao(db).replaceSnapshot([
          DataSampelPupuk(id: 9, kodeSampel: 'NBE/NPK/ABCD/01'),
        ]);

        expect(
          await notifier.addManual('NBE/NPK/C/01'),
          PupukLabManualResult.isSystemSample,
        );
        expect(
          await notifier.addManual('NBE/NPK/ABCD/01'),
          PupukLabManualResult.isSystemSample,
        );
        expect(
          await notifier.addManual('NBE/NPK/E/01'),
          PupukLabManualResult.added,
        );
      },
    );

    test('removing a sample also removes it from parameter rows', () {
      notifier.addScanned(scanned(5, 'W-001'));
      notifier.addScanned(scanned(6, 'W-002'));
      notifier.addParameter();

      expect(read().parameters.single.kodeSampel, ['W-001', 'W-002']);
      expect(read().parameters.single.totalSample, 2);

      notifier.removeSample('W-002');

      expect(read().kodes, ['W-001']);
      expect(read().parameters.single.kodeSampel, ['W-001']);
    });

    test(
      'a new sample joins only the parameters that covered every sample',
      () {
        notifier.addScanned(scanned(5, 'W-001'));
        notifier.addScanned(scanned(6, 'W-002'));
        notifier.addParameter();
        notifier.addParameter();
        final second = read().parameters.last.key;
        notifier.updateParameter(
          second,
          (p) => p.copyWith(kodeSampel: ['W-001']),
        );

        notifier.addScanned(scanned(7, 'W-003'));

        expect(read().parameters.first.kodeSampel, ['W-001', 'W-002', 'W-003']);
        expect(read().parameters.last.kodeSampel, ['W-001']);
      },
    );

    test('the memo moves the receipt date until the user picks one', () {
      notifier.setMemo(DateTime(2026, 10, 6, 14));
      expect(read().tanggalTerima, DateTime(2026, 10, 7));

      notifier.setTanggalTerima(DateTime(2026, 10, 9, 18, 30));
      expect(read().tanggalTerima, DateTime(2026, 10, 9));
      expect(read().tanggalTerimaEdited, isTrue);

      notifier.setMemo(DateTime(2026, 10, 6, 8));
      expect(read().tanggalTerima, DateTime(2026, 10, 9));
    });

    test('changing the jenis drops the parameter rows', () {
      final master = sampleMaster();
      notifier.setJenis(master, 1);
      notifier.addParameter();
      expect(read().parameters, hasLength(1));

      notifier.setJenis(master, 2);

      expect(read().parameters, isEmpty);
      expect(read().statusPengerjaan, 2);
    });

    test('photos are unique', () {
      notifier.addPhoto('/a.jpg');
      notifier.addPhoto('/a.jpg');
      notifier.addPhoto('/b.jpg');
      notifier.removePhoto('/a.jpg');

      expect(read().fotoPaths, ['/b.jpg']);
    });

    test('save rejects an invalid draft', () async {
      await expectLater(
        notifier.save(sampleMaster()),
        throwsA(isA<PupukLabInvalidException>()),
      );
      expect(await container.read(pupukLabDaoProvider).getAll(), isEmpty);
    });

    test(
      'save stores a new receipt, reserves its codes and clears dirty',
      () async {
        final master = sampleMaster();
        notifier.start(completeDraft(master).copyWith(dirty: true));

        final saved = await notifier.save(master);

        final rows = await container.read(pupukLabDaoProvider).getAll();
        expect(rows.single.id, saved.id);
        expect(rows.single.noSurat, 'SRS/001');
        expect(rows.single.status, 'not_uploaded');
        expect(rows.single.clientUuid, hasLength(36));
        expect(read().dirty, isFalse);
        expect(await container.read(reservedPupukLabKodeProvider.future), {
          'W-001',
          'W-002',
        });
        final savedSuggestions = await container
            .read(formCompletionSuggestionsDaoProvider)
            .getAll();
        expect(
          savedSuggestions
              .where((item) => item.type == FormCompletionSuggestionType.email)
              .map((item) => item.value),
          containsAll(['pelanggan@example.com', 'cs.labcbi@citraborneo.co.id']),
        );
      },
    );

    test(
      'saving an edit keeps the client uuid and resets a failed status',
      () async {
        final master = sampleMaster();
        final dao = container.read(pupukLabDaoProvider);
        final id = await dao.insert(
          samplePupukLab(
            clientUuid: 'uuid-keep',
            fotoPaths: const ['/tmp/terima-lab.jpg'],
          ),
        );
        await dao.markFailed(id, 'Parameter tidak valid', retryable: false);
        final stored = (await dao.getById(id))!;
        expect(stored.needsEdit, isTrue);

        notifier.start(
          PupukLabDraft.fromReceipt(
            receipt: stored,
            samples: [
              for (final s in stored.samples) PupukLabDraftSample(sample: s),
            ],
          ),
        );
        notifier.patch((d) => d.copyWith(tujuan: 'Tujuan baru'));
        await notifier.save(master);

        final after = (await dao.getById(id))!;
        expect(after.clientUuid, 'uuid-keep');
        expect(after.form.tujuan, 'Tujuan baru');
        expect(after.status, 'not_uploaded');
        expect(after.needsEdit, isFalse);
        expect(await dao.getAll(), hasLength(1));
      },
    );
  });

  group('PupukLabScanResolver', () {
    late AppDatabase db;
    late PupukLabScanResolver resolver;

    String qr(int id, String kode) => '$id^PT Pupuk^$kode^NPK 15-15-15^1000';

    String tracking(List<List<Object?>> rows) => jsonEncode(rows);

    DataSampelPupuk record(
      int id,
      String kode, {
      String? noSurat,
      String? kirimLab,
      String? registrasi,
      List<List<Object?>>? rows,
    }) => DataSampelPupuk(
      id: id,
      kodeSampel: kode,
      supplier: 'PT Pupuk',
      jenisPupuk: 'NPK 15',
      noSurat: noSurat,
      tanggalKirimLab: kirimLab,
      tanggalRegistrasiLab: registrasi,
      trackingSampelPupuk: rows == null ? null : tracking(rows),
    );

    Future<PupukLabScanResult> scan(
      String raw, {
      Set<String> existing = const {},
      String noSurat = '',
      Set<String> reserved = const {},
    }) => resolver.resolve(
      raw,
      existingKodes: existing,
      noSurat: noSurat,
      reservedKodes: reserved,
    );

    PupukLabScanProblem problemOf(PupukLabScanResult result) =>
        (result as PupukLabScanRejected).problem;

    setUp(() async {
      db = newTestDatabase();
      resolver = PupukLabScanResolver(DataSampelPupukDao(db));
      await DataSampelPupukDao(db).replaceSnapshot([
        record(1, 'W-1', kirimLab: '2026-10-01', noSurat: 'SRS/001'),
        record(2, 'W-2', kirimLab: '2026-10-01', noSurat: 'SRS/002'),
        record(3, 'W-3'),
        record(4, 'W-4', kirimLab: '2026-10-01', registrasi: '2026-10-02'),
        record(
          5,
          'NPK/ABCD',
          rows: [
            ['NPK/A', 'SRS/001', null, '2026-10-01', null],
            ['NPK/B', 'SRS/001', null, '2026-10-01', '2026-10-02'],
          ],
        ),
      ]);
    });

    tearDown(() => db.close());

    test('accepts an eligible sample and reports its no. surat', () async {
      final result = await scan(qr(1, 'W-1'));

      final accepted = result as PupukLabScanAccepted;
      expect(accepted.sample.kode, 'W-1');
      expect(accepted.sample.sample.dataSampelPupukId, 1);
      expect(accepted.sample.supplier, 'PT Pupuk');
      expect(accepted.sample.jenisPupuk, 'NPK 15');
      expect(accepted.sample.qtyKg, 1000);
      expect(accepted.noSurat, 'SRS/001');
    });

    test(
      'reads the no. surat of one individual sample from its tracking row',
      () async {
        final result = await scan(qr(5, 'NPK/A'));

        expect((result as PupukLabScanAccepted).noSurat, 'SRS/001');
      },
    );

    test('rejects each blocked state with its own problem', () async {
      expect(problemOf(await scan('bukan qr')), PupukLabScanProblem.invalidQr);
      expect(
        problemOf(await scan(qr(99, 'W-99'))),
        PupukLabScanProblem.notFound,
      );
      expect(
        problemOf(await scan(qr(3, 'W-3'))),
        PupukLabScanProblem.notSentToLab,
      );
      expect(
        problemOf(await scan(qr(4, 'W-4'))),
        PupukLabScanProblem.alreadyReceived,
      );
      expect(
        problemOf(await scan(qr(5, 'NPK/B'))),
        PupukLabScanProblem.alreadyReceived,
        reason: 'the individual tuple decides, not the record',
      );
      expect(
        problemOf(await scan(qr(1, 'W-1'), reserved: {'W-1'})),
        PupukLabScanProblem.reservedLocally,
      );
      expect(
        problemOf(await scan(qr(1, 'W-1'), existing: {'W-1'})),
        PupukLabScanProblem.duplicate,
      );
    });

    test(
      'a different no. surat than the receipt is refused and names both',
      () async {
        final result = await scan(qr(2, 'W-2'), noSurat: 'SRS/001');

        final rejected = result as PupukLabScanRejected;
        expect(rejected.problem, PupukLabScanProblem.noSuratMismatch);
        expect(rejected.message, contains('SRS/002'));
        expect(rejected.message, contains('SRS/001'));
      },
    );

    test('the same no. surat, or an empty receipt, is accepted', () async {
      expect(
        await scan(qr(1, 'W-1'), noSurat: 'SRS/001'),
        isA<PupukLabScanAccepted>(),
      );
      expect(
        await scan(qr(2, 'W-2'), noSurat: ''),
        isA<PupukLabScanAccepted>(),
      );
    });

    test(
      'describeSamples fills in display data and leaves manual codes alone',
      () async {
        final described = await resolver.describeSamples(const [
          PupukLabSample(dataSampelPupukId: 1, kodeSampel: 'W-1'),
          PupukLabSample(kodeSampel: 'MAN-1', isManual: true),
        ]);

        expect(described.first.supplier, 'PT Pupuk');
        expect(described.last.supplier, isNull);
        expect(described.last.isManual, isTrue);
      },
    );
  });
}
