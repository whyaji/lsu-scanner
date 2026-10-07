import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_form.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_master.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_sample.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_validation.dart';

import '../../helpers/pupuk_lab_fixtures.dart';

void main() {
  group('PupukLabForm JSON', () {
    test('toJson emits exactly the contract keys', () {
      final json = sampleForm(diskon: 10).toJson();

      expect(json.keys.toSet(), {
        'jenisSampelId',
        'jenisPupuk',
        'statusPengerjaan',
        'asalSampel',
        'tanggalMemo',
        'tanggalTerima',
        'estimasiKupa',
        'namaPengirim',
        'departemen',
        'kemasanSampel',
        'kondisiSampel',
        'tujuan',
        'skalaPrioritas',
        'peralatan',
        'penerimaSampel',
        'petugasPreperasi',
        'penyelia',
        'noDocument',
        'noDocumentIdentitas',
        'namaFormulir',
        'emailTo',
        'emailCc',
        'diskon',
        'konfirmasi',
        'noHp',
        'parameters',
        'catatan',
      });
      expect(json['parameters'], [
        {
          'parameterId': 10,
          'totalSample': 3,
          'kodeSampel': ['W-001', 'W-002', 'MANUAL-9'],
        },
        {
          'parameterId': 11,
          'totalSample': 1,
          'kodeSampel': ['W-001'],
        },
      ]);
      expect(json['diskon'], 10);
    });

    test('survives a JSON text round trip', () {
      final form = sampleForm(diskon: 5);
      final restored = PupukLabForm.fromJson(
        jsonDecode(jsonEncode(form.toJson())) as Map<String, dynamic>,
      );

      expect(jsonEncode(restored.toJson()), jsonEncode(form.toJson()));
      expect(restored.parameters.first, form.parameters.first);
    });

    test('fromJson accepts missing optional fields', () {
      final json = sampleForm().toJson()
        ..remove('petugasPreperasi')
        ..remove('catatan')
        ..remove('diskon')
        ..['konfirmasi'] = null;
      final form = PupukLabForm.fromJson(json);

      expect(form.petugasPreperasi, isNull);
      expect(form.catatan, isNull);
      expect(form.diskon, isNull);
      expect(form.konfirmasi, isFalse);
    });
  });

  group('defaultTanggalTerima', () {
    test('uses the memo day before noon', () {
      expect(
        PupukLabForm.defaultTanggalTerima(DateTime(2026, 10, 6, 11, 59)),
        DateTime(2026, 10, 6),
      );
    });

    test('adds one day from noon onwards, crossing month ends', () {
      expect(
        PupukLabForm.defaultTanggalTerima(DateTime(2026, 10, 6, 12)),
        DateTime(2026, 10, 7),
      );
      expect(
        PupukLabForm.defaultTanggalTerima(DateTime(2026, 10, 31, 23, 59)),
        DateTime(2026, 11, 1),
      );
    });
  });

  group('validate', () {
    final master = sampleMaster();

    PupukLabValidation run(
      PupukLabForm form, {
      List<PupukLabSample> samples = sampleSamples,
      String noSurat = 'SRS/001',
      int fotoCount = 1,
    }) => form.validate(
      samples: samples,
      noSurat: noSurat,
      fotoCount: fotoCount,
      master: master,
    );

    PupukLabValidation runWithoutMaster(PupukLabForm form) =>
        form.validate(samples: sampleSamples, noSurat: 'SRS/001', fotoCount: 1);

    test('a complete form passes', () {
      final result = run(sampleForm());
      expect(result.errors, isEmpty);
      expect(result.isValid, isTrue);
    });

    test('works without master data for the structural rules', () {
      expect(runWithoutMaster(sampleForm()).isValid, isTrue);
    });

    test('rejects estimasi before tanggal terima, accepts the same day', () {
      expect(
        run(sampleForm(estimasiKupa: '2026-10-06'))['estimasiKupa'],
        isNotNull,
      );
      expect(
        run(sampleForm(estimasiKupa: '2026-10-07'))['estimasiKupa'],
        isNull,
      );
    });

    test('rejects impossible and malformed dates', () {
      expect(
        run(sampleForm(tanggalTerima: '2026-02-30'))['tanggalTerima'],
        isNotNull,
      );
      expect(
        run(sampleForm(tanggalTerima: '07-10-2026'))['tanggalTerima'],
        isNotNull,
      );
    });

    test('requires at least one sample and at most 1000', () {
      expect(run(sampleForm(), samples: const [])['samples'], isNotNull);
      final tooMany = [
        for (var i = 0; i < 1001; i++)
          PupukLabSample(kodeSampel: 'M$i', isManual: true),
      ];
      expect(run(sampleForm(), samples: tooMany)['samples'], contains('1000'));
    });

    test('rejects duplicate and blank sample codes', () {
      final duplicate = [
        const PupukLabSample(kodeSampel: 'A', isManual: true),
        const PupukLabSample(kodeSampel: 'A', isManual: true),
      ];
      expect(run(sampleForm(), samples: duplicate)['samples'], contains('A'));
      expect(
        run(
          sampleForm(),
          samples: [const PupukLabSample(kodeSampel: '  ', isManual: true)],
        )['samples'],
        isNotNull,
      );
    });

    test('a parameter may appear only once', () {
      final form = sampleForm(
        parameters: const [
          PupukLabParameterEntry(
            parameterId: 10,
            totalSample: 1,
            kodeSampel: ['W-001'],
          ),
          PupukLabParameterEntry(
            parameterId: 10,
            totalSample: 2,
            kodeSampel: ['W-002'],
          ),
        ],
      );
      final result = run(form);
      expect(result['parameters.1.parameterId'], isNotNull);
      expect(result['parameters.0.parameterId'], isNull);
    });

    test('parameter kode must be a non-empty subset of the samples', () {
      final form = sampleForm(
        parameters: const [
          PupukLabParameterEntry(
            parameterId: 10,
            totalSample: 1,
            kodeSampel: ['W-001', 'NOT-LISTED'],
          ),
          PupukLabParameterEntry(
            parameterId: 11,
            totalSample: 1,
            kodeSampel: [],
          ),
        ],
      );
      final result = run(form);
      expect(result['parameters.0.kodeSampel'], contains('NOT-LISTED'));
      expect(result['parameters.1.kodeSampel'], isNotNull);
    });

    test('totalSample must be within 1..1000', () {
      final form = sampleForm(
        parameters: const [
          PupukLabParameterEntry(
            parameterId: 10,
            totalSample: 0,
            kodeSampel: ['W-001'],
          ),
          PupukLabParameterEntry(
            parameterId: 11,
            totalSample: 1001,
            kodeSampel: ['W-001'],
          ),
        ],
      );
      final result = run(form);
      expect(result['parameters.0.totalSample'], isNotNull);
      expect(result['parameters.1.totalSample'], isNotNull);
    });

    test('needs at least one parameter', () {
      expect(run(sampleForm(parameters: const []))['parameters'], isNotNull);
    });

    test('parameter must belong to the selected jenis', () {
      final form = sampleForm(
        parameters: const [
          PupukLabParameterEntry(
            parameterId: 20,
            totalSample: 1,
            kodeSampel: ['W-001'],
          ),
        ],
      );
      expect(run(form)['parameters.0.parameterId'], isNotNull);
      expect(runWithoutMaster(form)['parameters.0.parameterId'], isNull);
    });

    test('status pengerjaan must be allowed for the jenis', () {
      expect(
        run(sampleForm(statusPengerjaan: 2))['statusPengerjaan'],
        isNotNull,
      );
      expect(run(sampleForm(statusPengerjaan: 1))['statusPengerjaan'], isNull);
    });

    test('unknown jenis is reported', () {
      expect(run(sampleForm(jenisSampelId: 77))['jenisSampelId'], isNotNull);
    });

    test('emails and diskon are checked', () {
      expect(run(sampleForm(emailTo: const []))['emailTo'], isNotNull);
      expect(
        run(sampleForm(emailTo: const ['not-an-email']))['emailTo'],
        isNotNull,
      );
      expect(run(sampleForm(diskon: 100))['diskon'], isNotNull);
      expect(run(sampleForm(diskon: -1))['diskon'], isNotNull);
      expect(run(sampleForm(diskon: 99))['diskon'], isNull);
    });

    test('text fields enforce the 2..255 length', () {
      expect(run(sampleForm(), noSurat: 'x')['noSurat'], isNotNull);
      expect(run(sampleForm(), noSurat: 'x' * 256)['noSurat'], isNotNull);
      expect(run(sampleForm(), noSurat: 'ab')['noSurat'], isNull);
    });

    test('text limits follow the SmartLab column widths', () {
      PupukLabValidation with_(Map<String, Object?> patch) =>
          run(PupukLabForm.fromJson({...sampleForm().toJson(), ...patch}));

      expect(with_({'namaPengirim': 'x' * 51})['namaPengirim'], isNotNull);
      expect(with_({'namaPengirim': 'x' * 50})['namaPengirim'], isNull);
      expect(with_({'kemasanSampel': 'x' * 21})['kemasanSampel'], isNotNull);
      expect(with_({'kemasanSampel': 'x' * 20})['kemasanSampel'], isNull);
      expect(with_({'tujuan': 'x' * 101})['tujuan'], isNotNull);
      expect(with_({'penerimaSampel': 'x' * 51})['penerimaSampel'], isNotNull);
      expect(with_({'departemen': 'x' * 51})['departemen'], isNotNull);
      expect(with_({'departemen': ' '})['departemen'], isNotNull);
      expect(with_({'jenisPupuk': 'x' * 101})['jenisPupuk'], isNotNull);
      expect(with_({'penyelia': 'x' * 101})['penyelia'], isNotNull);
      expect(
        with_({'petugasPreperasi': 'x' * 501})['petugasPreperasi'],
        isNotNull,
      );
      expect(with_({'noDocument': 'x' * 256})['noDocument'], isNotNull);
      expect(with_({'penyelia': null})['penyelia'], isNull);
      expect(run(sampleForm(), noSurat: 'x' * 101)['noSurat'], isNotNull);
    });

    test('joined email_to is capped at 256 characters', () {
      final long = [for (var i = 0; i < 6; i++) '${'a' * 45}$i@example.com'];
      expect(run(sampleForm(emailTo: long))['emailTo'], contains('256'));
    });

    test('photos are capped at 5', () {
      PupukLabValidation fotos(int n) => sampleForm().validate(
        samples: sampleSamples,
        noSurat: 'SRS/001',
        fotoCount: n,
      );
      expect(fotos(0)['fotoPaths'], isNotNull);
      expect(fotos(1)['fotoPaths'], isNull);
      expect(fotos(5)['fotoPaths'], isNull);
      expect(fotos(6)['fotoPaths'], isNotNull);
    });

    test('codes must stay unique after SmartLab sanitizing', () {
      final samples = [
        const PupukLabSample(kodeSampel: 'A\$1', isManual: true),
        const PupukLabSample(kodeSampel: "A'1", isManual: true),
      ];
      expect(run(sampleForm(), samples: samples)['samples'], contains('A1'));
      expect(sanitizeKodeSampel('a"b\\c\$d\u0007e'), 'abcde');
    });

    test('options outside the master lists are rejected', () {
      final json = sampleForm().toJson()
        ..['kondisiSampel'] = 'Rusak'
        ..['peralatan'] = ['Palu'];
      final result = run(PupukLabForm.fromJson(json));
      expect(result['kondisiSampel'], isNotNull);
      expect(result['peralatan'], isNotNull);
    });
  });

  group('PupukLabMaster', () {
    final master = sampleMaster();

    test('fromApiJson and toJson round trip', () {
      expect(jsonEncode(master.toJson()), jsonEncode(masterApiJson()));
    });

    test('jenisById finds by id or returns null', () {
      expect(master.jenisById(2)!.nama, 'Tanah');
      expect(master.jenisById(404), isNull);
    });

    test('progressOptionsFor keeps jenis order and skips unknown ids', () {
      final options = master.progressOptionsFor(1);
      expect(options.map((p) => p.id), [3, 1]);
      expect(options.map((p) => p.nama), ['Selesai', 'Preparasi']);
      expect(master.progressOptionsFor(404), isEmpty);
    });

    test('parametersFor filters by jenis', () {
      expect(master.parametersFor(1).map((p) => p.id), [10, 11]);
      expect(master.parametersFor(2).map((p) => p.id), [20]);
      expect(master.parametersFor(3), isEmpty);
      expect(master.parameterById(11)!.harga, 15000.5);
    });

    test('tolerates missing sections', () {
      final empty = PupukLabMaster.fromApiJson({'version': 'v'});
      expect(empty.isUsable, isFalse);
      expect(empty.options.asalSampel, isEmpty);
      expect(empty.progressOptionsFor(1), isEmpty);
    });

    test('isOlderThan compares fetchedAt with the given clock', () {
      final now = DateTime.parse('2026-10-06T12:00:00.000Z');
      expect(master.isOlderThan(const Duration(hours: 24), now: now), isFalse);
      expect(master.isOlderThan(const Duration(hours: 10), now: now), isTrue);
      expect(
        PupukLabMaster.fromApiJson({}).isOlderThan(const Duration(days: 365)),
        isTrue,
      );
    });
  });
}
