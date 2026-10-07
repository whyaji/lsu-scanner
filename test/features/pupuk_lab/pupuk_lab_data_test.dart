import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/constants/app_constants.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_dao.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_master_dao.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_master_repository.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_sample.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/pupuk_lab_fixtures.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  group('PupukLabDao', () {
    late PupukLabDao dao;
    setUp(() => dao = PupukLabDao(db));

    test('insert and read back a receipt', () async {
      final id = await dao.insert(samplePupukLab());
      final row = (await dao.getById(id))!;

      expect(row.noSurat, 'SRS/001');
      expect(row.status, AppConstants.statusNotUploaded);
      expect(row.samples, sampleSamples);
    });

    test('client_uuid is unique', () async {
      await dao.insert(samplePupukLab());
      expect(
        () => dao.insert(samplePupukLab(noSurat: 'other')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'getPending returns not_uploaded and error rows newest first',
      () async {
        await dao.insert(
          samplePupukLab(clientUuid: 'a', createdAt: '2026-10-01T08:00:00'),
        );
        await dao.insert(
          samplePupukLab(
            clientUuid: 'b',
            status: 'error',
            createdAt: '2026-10-02T08:00:00',
          ),
        );
        await dao.insert(
          samplePupukLab(
            clientUuid: 'c',
            status: 'uploaded',
            createdAt: '2026-10-03T08:00:00',
          ),
        );

        expect((await dao.getPending()).map((e) => e.clientUuid), ['b', 'a']);
        expect(await dao.getAll(), hasLength(3));
      },
    );

    test(
      'markUploaded stores the SmartLab result and clears the error',
      () async {
        final id = await dao.insert(samplePupukLab(status: 'error'));
        await dao.updateStatus(id, 'error', errorMessage: 'gagal');

        await dao.markUploaded(
          id,
          kodeTrack: 'AB12CD3',
          nomorLab: '224\$226',
          nomorKupa: 7,
        );

        final row = (await dao.getById(id))!;
        expect(row.status, AppConstants.statusUploaded);
        expect(row.errorMessage, isNull);
        expect(row.kodeTrack, 'AB12CD3');
        expect(row.nomorLab, '224\$226');
        expect(row.nomorKupa, 7);
        expect(await dao.getPending(), isEmpty);
      },
    );

    test(
      'updateDraft keeps the client_uuid and puts the row back to pending',
      () async {
        final id = await dao.insert(samplePupukLab(status: 'error'));
        await dao.updateStatus(id, 'error', errorMessage: 'Parameter salah');
        final stored = (await dao.getById(id))!;

        final edited = samplePupukLab(
          id: id,
          clientUuid: 'must-be-ignored',
          noSurat: 'SRS/002',
          createdAt: '2000-01-01T00:00:00',
        );
        await dao.updateDraft(edited);

        final row = (await dao.getById(id))!;
        expect(row.clientUuid, stored.clientUuid);
        expect(row.createdAt, stored.createdAt);
        expect(row.noSurat, 'SRS/002');
        expect(row.status, AppConstants.statusNotUploaded);
        expect(row.errorMessage, isNull);
        expect(row.updatedAt, isNotNull);
      },
    );

    test('updateDraft needs a saved row', () {
      expect(() => dao.updateDraft(samplePupukLab()), throwsArgumentError);
    });

    test(
      'getReservedKodeSampel covers every status and can exclude one row',
      () async {
        final a = await dao.insert(
          samplePupukLab(
            clientUuid: 'a',
            samples: const [
              PupukLabSample(dataSampelPupukId: 1, kodeSampel: 'A1'),
            ],
          ),
        );
        await dao.insert(
          samplePupukLab(
            clientUuid: 'b',
            status: 'uploaded',
            samples: const [
              PupukLabSample(dataSampelPupukId: 2, kodeSampel: 'B1'),
              PupukLabSample(kodeSampel: 'M1', isManual: true),
            ],
          ),
        );

        expect(await dao.getReservedKodeSampel(), {'A1', 'B1', 'M1'});
        expect(await dao.getReservedKodeSampel(excludingId: a), {'B1', 'M1'});
      },
    );

    test('delete removes the receipt', () async {
      final id = await dao.insert(samplePupukLab());
      await dao.delete(id);
      expect(await dao.getById(id), isNull);
    });
  });

  group('PupukLabMasterDao', () {
    test('save replaces the single master row and load restores it', () async {
      final dao = PupukLabMasterDao(db);
      expect(await dao.load(), isNull);

      await dao.save(sampleMaster(), syncedAt: DateTime.utc(2026, 10, 6, 1));
      final newer = sampleMaster();
      await dao.save(newer, syncedAt: DateTime.utc(2026, 10, 6, 2));

      final rows = await (await db.database).query('pupuk_lab_master');
      expect(rows, hasLength(1));
      expect(rows.single['key'], 'master');
      expect(rows.single['version'], 'abc123');

      final stored = (await dao.load())!;
      expect(stored.master.jenisSampel, hasLength(2));
      expect(stored.syncedAt.toUtc(), DateTime.utc(2026, 10, 6, 2));

      await dao.clear();
      expect(await dao.load(), isNull);
    });
  });

  group('PupukLabMasterRepository', () {
    late DateTime now;
    late PupukLabMasterRepository repo;

    setUp(() {
      now = DateTime.utc(2026, 10, 6, 2);
      repo = PupukLabMasterRepository(PupukLabMasterDao(db), clock: () => now);
    });

    test('has no master before the first sync', () async {
      expect(await repo.hasMaster, isFalse);
      expect(await repo.load(), isNull);
    });

    test(
      'store caches in memory and persists for the next repository',
      () async {
        await repo.store(sampleMaster());

        final snapshot = (await repo.load())!;
        expect(snapshot.master.version, 'abc123');
        expect(snapshot.syncedAt, now);
        expect(snapshot.isStale, isFalse);
        expect(await repo.hasMaster, isTrue);

        final reopened = PupukLabMasterRepository(
          PupukLabMasterDao(db),
          clock: () => now,
        );
        expect((await reopened.load())!.master.version, 'abc123');
      },
    );

    test(
      'serverStale and markStale flag the snapshot, store resets it',
      () async {
        await repo.store(sampleMaster(), serverStale: true);
        expect((await repo.load())!.isStale, isTrue);

        await repo.store(sampleMaster());
        expect((await repo.load())!.isStale, isFalse);

        repo.markStale();
        expect((await repo.load())!.isStale, isTrue);
      },
    );

    test('becomes stale once fetchedAt is older than staleAfter', () async {
      await repo.store(sampleMaster());
      expect((await repo.load())!.isStale, isFalse);

      now = DateTime.utc(2026, 10, 8);
      expect((await repo.load())!.isStale, isTrue);
    });

    test('clear forgets the master', () async {
      await repo.store(sampleMaster());
      await repo.clear();
      expect(await repo.hasMaster, isFalse);
    });
  });
}
