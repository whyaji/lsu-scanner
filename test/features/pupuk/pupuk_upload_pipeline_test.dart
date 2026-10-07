import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/constants/app_constants.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/daos/kirim_dari_estate_dao.dart';
import 'package:sampletrack/core/database/daos/kirim_lab_dao.dart';
import 'package:sampletrack/core/database/daos/kirim_sertifikat_estate_dao.dart';
import 'package:sampletrack/core/database/models/kirim_dari_estate.dart';
import 'package:sampletrack/core/database/models/kirim_lab.dart';
import 'package:sampletrack/core/database/models/kirim_sertifikat_estate.dart';
import 'package:sampletrack/core/network/models/api_response.dart';
import 'package:sampletrack/features/pupuk/constants/pupuk_activity_types.dart';
import 'package:sampletrack/features/pupuk/providers/upload/pupuk_upload_pipeline.dart';
import 'package:sampletrack/features/pupuk/providers/upload/pupuk_upload_strategies.dart';
import 'package:sampletrack/features/pupuk/providers/upload/pupuk_upload_strategy.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_dao.dart';
import 'package:sampletrack/features/pupuk_lab/providers/pupuk_lab_upload_strategy.dart';

import '../../helpers/fake_upload_api.dart';
import '../../helpers/pupuk_lab_fixtures.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late KirimDariEstateDao estateDao;
  late KirimLabDao labDao;
  late KirimSertifikatEstateDao sertifikatDao;
  late PupukLabDao pupukLabDao;
  late FakeUploadApi api;
  late PupukUploadPipeline pipeline;

  setUp(() {
    db = newTestDatabase();
    estateDao = KirimDariEstateDao(db);
    labDao = KirimLabDao(db);
    sertifikatDao = KirimSertifikatEstateDao(db);
    pupukLabDao = PupukLabDao(db);
    api = FakeUploadApi();
    pipeline = PupukUploadPipeline(
      uploadApi: api,
      retryDelay: Duration.zero,
      compress: (path) async => null,
      strategies: [
        KirimDariEstateUploadStrategy(estateDao, api),
        KirimLabUploadStrategy(labDao, api),
        KirimSertifikatEstateUploadStrategy(sertifikatDao, api),
        PupukLabUploadStrategy(pupukLabDao, api),
      ],
    );
  });

  tearDown(() => db.close());

  Future<int> addEstate(String kode, {String? foto}) => estateDao.insert(
    KirimDariEstate(
      dataSampelPupukId: 1,
      kodeSampel: kode,
      tanggalKirimDariEstate: '2026-10-01',
      fotoKirimDariEstate: foto,
      namaPengirim: 'Andi',
      createdAt: '2026-10-01T08:00:00',
    ),
  );

  Future<int> addLab(
    String kode, {
    String? noSurat,
    String? foto,
    String createdAt = '2026-10-01T08:00:00',
  }) => labDao.insert(
    KirimLab(
      dataSampelPupukId: 2,
      kodeSampel: kode,
      noSurat: noSurat,
      tanggalKirimLab: '2026-10-02',
      fotoKirimLab: foto,
      createdAt: createdAt,
    ),
  );

  Future<int> addSertifikat(String kode, String file) => sertifikatDao.insert(
    KirimSertifikatEstate(
      dataSampelPupukId: 3,
      kodeSampel: kode,
      tanggalKirimSertifikatEstate: '2026-10-03',
      rekomendasi: 'Layak',
      fileSertifikat: file,
      createdAt: '2026-10-01T08:00:00',
    ),
  );

  Future<int> addPupukLab(
    String uuid, {
    List<String> fotos = const [],
    String noSurat = 'SRS/001',
  }) => pupukLabDao.insert(
    samplePupukLab(clientUuid: uuid, fotoPaths: fotos, noSurat: noSurat),
  );

  test('does nothing and calls no API when nothing is pending', () async {
    final outcome = await pipeline.run();

    expect(outcome.total, 0);
    expect(outcome.byType, isEmpty);
    expect(api.uploadCalls, 0);
    expect(api.pupukPhotoCalls, isEmpty);
  });

  test(
    'uploads every type, reuses shared photos and stores the verdicts',
    () async {
      await addEstate('E-1', foto: '/local/e1.jpg');
      final lab1 = await addLab(
        'L-1',
        noSurat: 'S/1',
        foto: '/local/batch.jpg',
      );
      final lab2 = await addLab(
        'L-2',
        noSurat: 'S/1',
        foto: '/local/batch.jpg',
      );
      final lab3 = await addLab(
        'L-3',
        noSurat: 'S/2',
        foto: '/local/other.jpg',
      );
      final sert1 = await addSertifikat('C-1', '/local/cert.pdf');
      final sert2 = await addSertifikat('C-2', '/local/cert.pdf');
      final labId = await addPupukLab(
        'uuid-1',
        fotos: ['/local/a.jpg', '/local/b.jpg'],
      );
      api.respond = acceptAll;

      final progress = <UploadSampelPupukProgress>[];
      final outcome = await pipeline.run(onProgress: progress.add);

      expect(outcome.total, 7);
      expect(outcome.uploaded, 7);
      expect(outcome.failed, 0);
      expect(outcome.error, isNull);
      expect(
        outcome.byType.keys.toSet(),
        kUploadablePupukActivityTypes.toSet(),
      );

      expect(api.uploadCalls, 1);
      expect(api.pupukPhotoCalls, hasLength(4), reason: 'one per shared photo');
      expect(
        api.pupukPhotoCalls.where((c) => c.startsWith('kirimLab|')),
        hasLength(2),
      );
      expect(api.labPhotoCalls, ['uuid-1|/local/a.jpg', 'uuid-1|/local/b.jpg']);

      final json = api.lastPayload!.toJson();
      expect(
        (json[kKirimDariEstate] as List).single['fotoKirimDariEstate'],
        '/protected/pupuk/e1.jpg',
      );
      final labItems = (json[kKirimLab] as List).cast<Map<String, dynamic>>();
      expect(labItems, hasLength(3));
      expect(
        labItems.where(
          (i) => i['fotoKirimLab'] == '/protected/pupuk/batch.jpg',
        ),
        hasLength(2),
      );
      expect(
        (json[kKirimSertifikatEstate] as List).every(
          (i) => i['fileSertifikat'] == '/protected/pupuk/cert.pdf',
        ),
        isTrue,
      );
      final pupukLabItem = (json[kPupukLab] as List).single as Map;
      expect(pupukLabItem['id'], labId);
      expect(pupukLabItem['clientUuid'], 'uuid-1');
      expect(pupukLabItem['fotoPaths'], [
        '/protected/pupuk-lab/uuid-1-a.jpg',
        '/protected/pupuk-lab/uuid-1-b.jpg',
      ]);
      expect(pupukLabItem['form'], isA<Map>());

      expect(await estateDao.getPending(), isEmpty);
      expect(await labDao.getPending(), isEmpty);
      expect(await sertifikatDao.getPending(), isEmpty);
      for (final id in [lab1, lab2, lab3]) {
        expect((await labDao.getById(id))!.status, AppConstants.statusUploaded);
      }
      for (final id in [sert1, sert2]) {
        expect(
          (await sertifikatDao.getById(id))!.status,
          AppConstants.statusUploaded,
        );
      }
      final stored = (await pupukLabDao.getById(labId))!;
      expect(stored.status, AppConstants.statusUploaded);
      expect(stored.kodeTrack, 'TRK$labId');
      expect(stored.nomorLab, '1\$$labId');
      expect(stored.nomorKupa, 10 + labId);

      expect(progress.last.total, 7);
      expect(progress.last.current, 7);
      expect(progress.last.percentage, 100);
      expect(
        progress.map((e) => e.current),
        everyElement(inInclusiveRange(1, 7)),
      );
      expect(progress.any((e) => e.currentItem == 'L-1 (+1 sampel)'), isTrue);
    },
  );

  test(
    'partial failure keeps failed rows in error with the server message',
    () async {
      final okLab = await addLab('L-OK');
      final badLab = await addLab('L-BAD');
      final permanent = await addPupukLab('uuid-perm', noSurat: 'SRS/PERM');
      final transient = await addPupukLab('uuid-temp', noSurat: 'SRS/TEMP');
      api.respond = (payload) => ok({
        kKirimLab: {
          'success': [
            {'id': okLab},
          ],
          'failed': [
            {'id': badLab, 'error': 'Sampel tidak ditemukan'},
          ],
        },
        kPupukLab: {
          'success': [],
          'failed': [
            {
              'id': permanent,
              'error': 'Parameter tidak valid',
              'retryable': false,
            },
            {
              'id': transient,
              'error': 'SmartLab tidak dapat dihubungi',
              'retryable': true,
            },
          ],
        },
      });

      final outcome = await pipeline.run();

      expect(outcome.uploaded, 1);
      expect(outcome.failed, 3);
      final labResult = outcome.byType[kKirimLab]!;
      expect(labResult.failures.single.label, 'L-BAD');
      expect(labResult.failures.single.message, 'Sampel tidak ditemukan');

      final pupukLabFailures = outcome.byType[kPupukLab]!.failures;
      expect(
        {for (final f in pupukLabFailures) f.label: f.retryable},
        {'SRS/PERM': false, 'SRS/TEMP': true},
      );

      expect((await labDao.getById(badLab))!.status, AppConstants.statusError);
      expect(
        (await labDao.getById(badLab))!.errorMessage,
        'Sampel tidak ditemukan',
      );
      expect(
        (await labDao.getById(okLab))!.status,
        AppConstants.statusUploaded,
      );
      for (final id in [permanent, transient]) {
        expect(
          (await pupukLabDao.getById(id))!.status,
          AppConstants.statusError,
        );
      }
      expect(
        (await pupukLabDao.getById(permanent))!.errorMessage,
        'Parameter tidak valid',
      );
      expect(
        await pupukLabDao.getPending(),
        hasLength(2),
        reason: 'failed receipts are retried by the next upload',
      );
    },
  );

  test(
    'a permanent SmartLab rejection is skipped, with its photos, until edited',
    () async {
      final id = await addPupukLab('uuid-perm', fotos: ['/local/a.jpg']);
      api.respond = (_) => ok({
        kPupukLab: {
          'success': [],
          'failed': [
            {'id': id, 'error': 'Parameter tidak valid', 'retryable': false},
          ],
        },
      });
      await pipeline.run();

      final rejected = (await pupukLabDao.getById(id))!;
      expect(rejected.needsEdit, isTrue);
      expect(rejected.errorRetryable, isFalse);

      api.labPhotoCalls.clear();
      api.uploadCalls = 0;
      final second = await pipeline.run();
      expect(second.total, 0);
      expect(api.uploadCalls, 0);
      expect(api.labPhotoCalls, isEmpty);

      await pupukLabDao.updateDraft(rejected);
      final edited = (await pupukLabDao.getById(id))!;
      expect(edited.needsEdit, isFalse);
      expect(edited.status, AppConstants.statusNotUploaded);

      api.respond = (_) => ok({
        kPupukLab: {
          'success': [
            {
              'id': id,
              'kodeTrack': 'AB12CD3',
              'nomorLab': '1\$2',
              'nomorKupa': 1,
              'duplicate': false,
            },
          ],
          'failed': [],
        },
      });
      final third = await pipeline.run();
      expect(third.uploaded, 1);
      expect(api.labPhotoCalls, hasLength(1));
    },
  );

  test('a retryable failure is sent again by the next upload', () async {
    final id = await addPupukLab('uuid-temp');
    api.respond = (_) => ok({
      kPupukLab: {
        'success': [],
        'failed': [
          {
            'id': id,
            'error': 'SmartLab tidak dapat dihubungi',
            'retryable': true,
          },
        ],
      },
    });
    await pipeline.run();
    expect((await pupukLabDao.getById(id))!.needsEdit, isFalse);

    api.uploadCalls = 0;
    await pipeline.run();
    expect(api.uploadCalls, 1);
  });

  test('a server duplicate counts as uploaded', () async {
    final id = await addPupukLab('uuid-dup');
    api.respond = (_) => ok({
      kPupukLab: {
        'success': [
          {
            'id': id,
            'kodeTrack': 'DUP1234',
            'nomorLab': '5\$6',
            'nomorKupa': 3,
            'duplicate': true,
          },
        ],
        'failed': [],
      },
    });

    final outcome = await pipeline.run();

    expect(outcome.uploaded, 1);
    expect(outcome.failed, 0);
    expect((await pupukLabDao.getById(id))!.kodeTrack, 'DUP1234');
  });

  test(
    'a photo that fails once is retried and the row still uploads',
    () async {
      await addEstate('E-1', foto: '/local/flaky.jpg');
      api.failuresLeft['/local/flaky.jpg'] = 1;
      api.respond = acceptAll;

      final outcome = await pipeline.run();

      expect(api.pupukPhotoCalls, hasLength(2));
      expect(outcome.uploaded, 1);
      expect(outcome.failed, 0);
    },
  );

  test(
    'a photo that fails twice marks the whole group and skips the payload',
    () async {
      final a = await addLab('L-1', noSurat: 'S/1', foto: '/local/dead.jpg');
      final b = await addLab('L-2', noSurat: 'S/1', foto: '/local/dead.jpg');
      final c = await addSertifikat('C-1', '/local/cert.pdf');
      api.failuresLeft['/local/dead.jpg'] = 2;
      api.failuresLeft['/local/cert.pdf'] = 2;
      api.respond = acceptAll;

      final outcome = await pipeline.run();

      expect(api.pupukPhotoCalls, hasLength(4));
      expect(api.uploadCalls, 0, reason: 'no item survived, so no request');
      expect(outcome.total, 3);
      expect(outcome.uploaded, 0);
      expect(outcome.failed, 3);

      for (final id in [a, b]) {
        final row = (await labDao.getById(id))!;
        expect(row.status, AppConstants.statusError);
        expect(row.errorMessage, 'Gagal mengunggah foto');
      }
      expect(
        (await sertifikatDao.getById(c))!.errorMessage,
        'Gagal mengunggah file sertifikat',
      );
      expect(
        outcome.byType[kKirimLab]!.failures.every((f) => f.retryable),
        isTrue,
      );
    },
  );

  test(
    'photo failures do not block rows of other types or other groups',
    () async {
      final dead = await addLab(
        'L-DEAD',
        noSurat: 'S/1',
        foto: '/local/dead.jpg',
      );
      final fine = await addLab(
        'L-FINE',
        noSurat: 'S/2',
        foto: '/local/fine.jpg',
      );
      api.failuresLeft['/local/dead.jpg'] = 2;
      api.respond = acceptAll;

      final outcome = await pipeline.run();

      expect(outcome.uploaded, 1);
      expect(outcome.failed, 1);
      expect((await labDao.getById(dead))!.status, AppConstants.statusError);
      expect((await labDao.getById(fine))!.status, AppConstants.statusUploaded);
      final sent = (api.lastPayload!.toJson()[kKirimLab] as List);
      expect(sent.single['id'], fine);
    },
  );

  test('a Terima Lab photo failure marks only that receipt', () async {
    final broken = await addPupukLab(
      'uuid-broken',
      fotos: ['/local/ok.jpg', '/local/bad.jpg'],
    );
    final clean = await addPupukLab('uuid-clean', noSurat: 'SRS/002');
    api.failuresLeft['/local/bad.jpg'] = 2;
    api.respond = acceptAll;

    final outcome = await pipeline.run();

    expect(outcome.uploaded, 1);
    expect(
      (await pupukLabDao.getById(broken))!.status,
      AppConstants.statusError,
    );
    expect(
      (await pupukLabDao.getById(broken))!.errorMessage,
      'Gagal mengunggah foto',
    );
    expect(
      (await pupukLabDao.getById(clean))!.status,
      AppConstants.statusUploaded,
    );
    expect((api.lastPayload!.toJson()[kPupukLab] as List), hasLength(1));
  });

  test(
    'a failed request leaves rows pending and reports every row failed',
    () async {
      final lab = await addLab('L-1');
      final pupukLab = await addPupukLab('uuid-1');
      api.respond = (_) => ApiResponse(
        success: false,
        error: ApiError(code: 'NETWORK_ERROR', message: 'Tidak ada koneksi'),
      );

      final outcome = await pipeline.run();

      expect(outcome.error, 'Tidak ada koneksi');
      expect(outcome.total, 2);
      expect(outcome.uploaded, 0);
      expect(outcome.failed, 2);
      expect(outcome.byType[kPupukLab]!.failures.single.retryable, isTrue);
      expect(
        (await labDao.getById(lab))!.status,
        AppConstants.statusNotUploaded,
      );
      expect(
        (await pupukLabDao.getById(pupukLab))!.status,
        AppConstants.statusNotUploaded,
      );
    },
  );

  test('every payload type key is present even when empty', () async {
    await addLab('L-1');
    api.respond = acceptAll;

    await pipeline.run();

    final json = api.lastPayload!.toJson();
    expect(json.keys, kUploadablePupukActivityTypes);
    expect(json[kPupukLab], isEmpty);
    expect(json[kKirimDariEstate], isEmpty);
  });

  test('rows already uploaded are not sent again', () async {
    await addLab('L-1');
    api.respond = acceptAll;
    await pipeline.run();

    final second = await pipeline.run();

    expect(second.total, 0);
    expect(api.uploadCalls, 1);
  });

  test(
    'the Kirim Lab group key falls back to the photo when no. surat is blank',
    () async {
      await addLab('L-1', foto: '/local/same.jpg');
      await addLab('L-2', noSurat: '  ', foto: '/local/same.jpg');
      await addLab('L-3', noSurat: 'S/9', foto: '/local/same.jpg');
      api.respond = acceptAll;

      await pipeline.run();

      expect(
        api.pupukPhotoCalls.where((c) => c.startsWith('kirimLab|')),
        hasLength(2),
        reason: 'blank no. surat rows share one upload, S/9 gets its own',
      );
    },
  );
}
