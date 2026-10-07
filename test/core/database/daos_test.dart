import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/constants/app_constants.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/daos/data_sampel_pupuk_dao.dart';
import 'package:sampletrack/core/database/daos/kirim_dari_estate_dao.dart';
import 'package:sampletrack/core/database/daos/kirim_lab_dao.dart';
import 'package:sampletrack/core/database/daos/kirim_sertifikat_estate_dao.dart';
import 'package:sampletrack/core/database/daos/lsu_dao.dart';
import 'package:sampletrack/core/database/daos/preferences_dao.dart';
import 'package:sampletrack/core/database/models/completed_sample.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/kirim_dari_estate.dart';
import 'package:sampletrack/core/database/models/kirim_lab.dart';
import 'package:sampletrack/core/database/models/kirim_sertifikat_estate.dart';
import 'package:sampletrack/core/database/models/master_lsu.dart';
import 'package:sampletrack/core/database/models/master_sampel.dart';
import 'package:sampletrack/core/database/models/received_sample.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database.dart';

KirimLab kirimLab(
  int dataId,
  String kode, {
  String createdAt = '2026-10-01T08:00:00',
  String? noSurat,
  String status = 'not_uploaded',
}) => KirimLab(
  dataSampelPupukId: dataId,
  kodeSampel: kode,
  noSurat: noSurat,
  tanggalKirimLab: '2026-10-01',
  status: status,
  createdAt: createdAt,
);

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  group('PreferencesDao', () {
    test(
      'set overwrites, get returns null for unknown, delete removes',
      () async {
        final dao = PreferencesDao(db);
        expect(await dao.get('a'), isNull);

        await dao.set('a', '1');
        await dao.set('a', '2');
        expect(await dao.get('a'), '2');

        await dao.delete('a');
        expect(await dao.get('a'), isNull);
      },
    );
  });

  group('DataSampelPupukDao', () {
    late DataSampelPupukDao dao;

    DataSampelPupuk sample(
      int id,
      String kode, {
      int regional = 1,
      String? noSertifikat,
      String? kirimSertifikat,
      String? noSurat,
      String? tracking,
    }) => DataSampelPupuk(
      id: id,
      kodeSampel: kode,
      regional: regional,
      noSertifikat: noSertifikat,
      tanggalKirimSertifikatEstate: kirimSertifikat,
      noSurat: noSurat,
      trackingSampelPupuk: tracking,
    );

    setUp(() => dao = DataSampelPupukDao(db));

    test('replaceSnapshot with a regional keeps other regionals', () async {
      await dao.replaceSnapshot([
        sample(1, 'B', regional: 1),
        sample(2, 'A', regional: 2),
      ]);
      await dao.replaceSnapshot([sample(3, 'C', regional: 1)], regional: 1);

      final all = await dao.getAll();
      expect(all.map((e) => e.id), [2, 3]);
    });

    test('replaceSnapshot without a regional replaces everything', () async {
      await dao.replaceSnapshot([sample(1, 'A', regional: 1)]);
      await dao.replaceSnapshot([sample(2, 'B', regional: 2)]);

      expect((await dao.getAll()).map((e) => e.id), [2]);
    });

    test('replaceSnapshot upserts by id inside the regional', () async {
      await dao.replaceSnapshot([sample(1, 'OLD')]);
      await dao.replaceSnapshot([sample(1, 'NEW')], regional: 1);

      expect((await dao.getById(1))!.kodeSampel, 'NEW');
    });

    test('getAll orders by kode and filters by regional', () async {
      await dao.replaceSnapshot([
        sample(1, 'C', regional: 1),
        sample(2, 'A', regional: 2),
        sample(3, 'B', regional: 1),
      ]);

      expect((await dao.getAll()).map((e) => e.kodeSampel), ['A', 'B', 'C']);
      expect((await dao.getAll(regional: 1)).map((e) => e.kodeSampel), [
        'B',
        'C',
      ]);
    });

    test('lab columns round trip through the table', () async {
      await dao.replaceSnapshot([
        DataSampelPupuk(
          id: 9,
          kodeSampel: 'W-9',
          registrasiLabBy: 42,
          pupukLabTerimaId: 77,
        ),
      ]);

      final row = (await dao.getById(9))!;
      expect(row.registrasiLabBy, 42);
      expect(row.pupukLabTerimaId, 77);
    });

    test(
      'getEligibleKirimSertifikat needs a certificate and no send date',
      () async {
        await dao.replaceSnapshot([
          sample(1, 'A', noSertifikat: 'CERT-1'),
          sample(2, 'B', noSertifikat: '  '),
          sample(3, 'C'),
          sample(4, 'D', noSertifikat: 'CERT-4', kirimSertifikat: '2026-10-02'),
          sample(5, 'E', noSertifikat: 'CERT-5', kirimSertifikat: ' '),
        ]);

        final eligible = await dao.getEligibleKirimSertifikat();
        expect(eligible.map((e) => e.id), [1, 5]);
      },
    );

    test(
      'updateTanggalKirimSertifikatEstate only sets rekomendasi when given',
      () async {
        await dao.replaceSnapshot([sample(1, 'A')]);

        await dao.updateTanggalKirimSertifikatEstate(1, '2026-10-03');
        var row = (await dao.getById(1))!;
        expect(row.tanggalKirimSertifikatEstate, '2026-10-03');
        expect(row.rekomendasi, isNull);

        await dao.updateTanggalKirimSertifikatEstate(
          1,
          '2026-10-04',
          rekomendasi: 'Layak',
        );
        row = (await dao.getById(1))!;
        expect(row.rekomendasi, 'Layak');
      },
    );

    test(
      'resolveNoSurat prefers synced data, then the latest local Kirim Lab row',
      () async {
        final labDao = KirimLabDao(db);
        expect(await dao.resolveNoSurat(1), isNull);
        expect(await dao.resolveNoSurat(1, fromData: '  S/9 '), 'S/9');

        await labDao.insert(kirimLab(1, 'A', noSurat: 'S/OLD'));
        await labDao.insert(kirimLab(1, 'A', noSurat: 'S/NEW'));
        expect(await dao.resolveNoSurat(1, fromData: ' '), 'S/NEW');

        await labDao.insert(kirimLab(2, 'B', noSurat: '   '));
        expect(await dao.resolveNoSurat(2), isNull);
      },
    );

    test('getAktivitas returns null for an unknown record', () async {
      expect(await dao.getAktivitas(404), isNull);
    });

    test('getAktivitas loads the latest row per activity', () async {
      await dao.replaceSnapshot([sample(1, 'W-1')]);
      final labDao = KirimLabDao(db);
      final estateDao = KirimDariEstateDao(db);
      await labDao.insert(kirimLab(1, 'W-1', noSurat: 'first'));
      await labDao.insert(kirimLab(1, 'W-2', noSurat: 'second'));
      await estateDao.insert(
        KirimDariEstate(
          dataSampelPupukId: 1,
          kodeSampel: 'W-1',
          tanggalKirimDariEstate: '2026-09-30',
          createdAt: '2026-09-30T08:00:00',
        ),
      );

      final aktivitas = (await dao.getAktivitas(1))!;
      expect(aktivitas.kodeSampel, 'W-1');
      expect(aktivitas.kirimLab!.noSurat, 'second');
      expect(aktivitas.kirimDariEstate, isNotNull);
      expect(aktivitas.kirimSertifikatEstate, isNull);
    });

    test(
      'getAktivitas with an individual kode only matches that kode',
      () async {
        await dao.replaceSnapshot([sample(1, 'BATCH')]);
        final labDao = KirimLabDao(db);
        await labDao.insert(kirimLab(1, 'W-1', noSurat: 'for-1'));
        await labDao.insert(kirimLab(1, 'W-2', noSurat: 'for-2'));

        final forOne = (await dao.getAktivitas(
          1,
          individualKodeSampel: 'W-1',
        ))!;
        expect(forOne.kodeSampel, 'W-1');
        expect(forOne.kirimLab!.noSurat, 'for-1');

        final forOther = (await dao.getAktivitas(
          1,
          individualKodeSampel: 'W-3',
        ))!;
        expect(forOther.kodeSampel, 'W-3');
        expect(forOther.kirimLab, isNull);
      },
    );
  });

  group('activity tables', () {
    test(
      'KirimLabDao pending returns not_uploaded and error, newest first',
      () async {
        final dao = KirimLabDao(db);
        await dao.insert(kirimLab(1, 'old', createdAt: '2026-10-01T08:00:00'));
        await dao.insert(
          kirimLab(1, 'new', createdAt: '2026-10-02T08:00:00', status: 'error'),
        );
        await dao.insert(
          kirimLab(
            1,
            'done',
            createdAt: '2026-10-03T08:00:00',
            status: 'uploaded',
          ),
        );

        expect((await dao.getPending()).map((e) => e.kodeSampel), [
          'new',
          'old',
        ]);
        expect((await dao.getAll()).map((e) => e.kodeSampel), [
          'done',
          'new',
          'old',
        ]);
      },
    );

    test('insert ignores a preset id and returns the new one', () async {
      final dao = KirimLabDao(db);
      final id = await dao.insert(
        KirimLab(
          id: 99,
          dataSampelPupukId: 1,
          kodeSampel: 'A',
          tanggalKirimLab: '2026-10-01',
          createdAt: '2026-10-01T08:00:00',
        ),
      );
      expect(id, 1);
      expect((await dao.getById(1))!.kodeSampel, 'A');
    });

    test('updateStatus stores the error and stamps updated_at', () async {
      final dao = KirimDariEstateDao(db);
      final id = await dao.insert(
        KirimDariEstate(
          dataSampelPupukId: 1,
          kodeSampel: 'A',
          tanggalKirimDariEstate: '2026-10-01',
          createdAt: '2026-10-01T08:00:00',
        ),
      );

      await dao.updateStatus(
        id,
        AppConstants.statusError,
        errorMessage: 'Gagal',
      );
      var row = (await dao.getById(id))!;
      expect(row.status, 'error');
      expect(row.errorMessage, 'Gagal');
      expect(row.updatedAt, isNotNull);

      await dao.updateStatus(id, AppConstants.statusUploaded);
      row = (await dao.getById(id))!;
      expect(row.status, 'uploaded');
      expect(row.errorMessage, isNull);
      expect(await dao.getPending(), isEmpty);
    });

    test('delete removes the row', () async {
      final dao = KirimSertifikatEstateDao(db);
      final id = await dao.insert(
        KirimSertifikatEstate(
          dataSampelPupukId: 1,
          kodeSampel: 'A',
          tanggalKirimSertifikatEstate: '2026-10-01',
          rekomendasi: 'Layak',
          fileSertifikat: '/tmp/a.pdf',
          createdAt: '2026-10-01T08:00:00',
        ),
      );

      expect(await dao.delete(id), 1);
      expect(await dao.getById(id), isNull);
    });
  });

  group('LsuDao', () {
    late LsuDao dao;
    setUp(() => dao = LsuDao(db));

    ReceivedSample received(
      int dataLsuId, {
      String status = 'not_uploaded',
      String createdAt = '2026-10-01T08:00:00',
    }) => ReceivedSample(
      dataLsuId: dataLsuId,
      masterLsuId: 1,
      kode: 'K$dataLsuId',
      tanggalTerima: '2026-10-01',
      waktuTerima: '08:00:00',
      fotoPath: '/tmp/$dataLsuId.jpg',
      status: status,
      createdAt: createdAt,
    );

    test('master data batch insert, lookup and clear', () async {
      await dao.insertMasterSampelBatch([
        MasterSampel(id: 1, nama: 'Daun'),
        MasterSampel(id: 2, nama: 'Tanah'),
      ]);
      await dao.insertMasterLsuBatch([
        MasterLsu(id: 10, regional: 2, pt: 'PT A'),
      ]);

      expect((await dao.getMasterLsuById(10))!.regional, 2);
      expect(await dao.getMasterLsuById(11), isNull);
      expect(await dao.clearMasterSampel(), 2);
      expect(await dao.clearMasterLsu(), 1);
      expect(await dao.getMasterLsuById(10), isNull);
    });

    test('received rows: pending, uploaded and unique data_lsu_id', () async {
      await dao.received.insert(received(1, createdAt: '2026-10-01T08:00:00'));
      await dao.received.insert(
        received(2, status: 'uploaded', createdAt: '2026-10-02T08:00:00'),
      );
      await dao.received.insert(
        received(3, status: 'error', createdAt: '2026-10-03T08:00:00'),
      );

      expect((await dao.received.getPending()).map((e) => e.dataLsuId), [3, 1]);
      expect((await dao.received.getUploaded()).map((e) => e.dataLsuId), [2]);
      expect((await dao.received.getByDataLsuId(2))!.kode, 'K2');
      expect(await dao.received.getByDataLsuId(9), isNull);
      expect(
        () => dao.received.insert(received(1)),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('completed rows: insert, byDataLsuId and updateStatus', () async {
      final id = await dao.completed.insert(
        CompletedSample(
          dataLsuId: 5,
          masterLsuId: 1,
          kode: 'K5',
          tanggalSelesai: '2026-10-01',
          waktuSelesai: '09:00:00',
          fotoPath: '/tmp/5.jpg',
          createdAt: '2026-10-01T09:00:00',
        ),
      );

      expect((await dao.completed.getByDataLsuId(5))!.id, id);
      await dao.completed.updateStatus(id, AppConstants.statusUploaded);
      expect(await dao.completed.getPending(), isEmpty);
    });
  });
}
