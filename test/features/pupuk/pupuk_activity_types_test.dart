import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/constants/permission_constants.dart';
import 'package:sampletrack/core/database/models/aktivitas_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/kirim_lab.dart';
import 'package:sampletrack/features/pupuk/constants/pupuk_activity_types.dart';

const estate = PermissionConstants.pupukMobileKirimEstate;
const lab = PermissionConstants.pupukMobileKirimLab;
const pupukLab = PermissionConstants.pupukMobilePupukLab;

String tracking(List<List<Object?>> entries) => jsonEncode(entries);

DataSampelPupuk data({
  String? kode = 'BATCH',
  String? kirimLab,
  String? registrasiLab,
  String? fotoKirimLab,
  String? trackingJson,
}) => DataSampelPupuk(
  id: 1,
  kodeSampel: kode,
  tanggalKirimLab: kirimLab,
  tanggalRegistrasiLab: registrasiLab,
  fotoKirimLab: fotoKirimLab,
  trackingSampelPupuk: trackingJson,
);

AktivitasSampelPupuk aktivitas(DataSampelPupuk d, {KirimLab? kirimLab}) =>
    AktivitasSampelPupuk(
      id: d.id,
      kodeSampel: d.kodeSampel ?? '',
      dataSampelPupuk: d,
      kirimLab: kirimLab,
    );

void main() {
  test('constants and labels', () {
    expect(kPupukLab, 'pupukLab');
    expect(labelForPupukActivityType(kPupukLab), 'Terima Lab');
    expect(kUploadablePupukActivityTypes, [
      kKirimDariEstate,
      kKirimLab,
      kKirimSertifikatEstate,
      kPupukLab,
    ]);
  });

  group('homePupukActivityTypes', () {
    test('lists one shortcut per permission', () {
      expect(homePupukActivityTypes([estate]), [kKirimDariEstate]);
      expect(homePupukActivityTypes([lab]), [kKirimLab]);
      expect(homePupukActivityTypes([pupukLab]), [kPupukLab]);
      expect(homePupukActivityTypes([estate, lab, pupukLab]), [
        kKirimDariEstate,
        kKirimLab,
        kPupukLab,
      ]);
    });

    test('is empty without permissions', () {
      expect(homePupukActivityTypes(null), isEmpty);
      expect(homePupukActivityTypes(const []), isEmpty);
      expect(
        homePupukActivityTypes([
          PermissionConstants.pupukMobileKirimSertifikat,
        ]),
        isEmpty,
      );
    });
  });

  group('allowedPupukActivityTypes for a whole record', () {
    test('Terima Lab needs Kirim Lab done and Registrasi Lab empty', () {
      final sent = data(kirimLab: '2026-10-01');
      expect(allowedPupukActivityTypes([pupukLab], aktivitas(sent)), [
        kPupukLab,
      ]);

      expect(
        allowedPupukActivityTypes([pupukLab], aktivitas(data())),
        isEmpty,
        reason: 'not sent to the lab yet',
      );
      expect(
        allowedPupukActivityTypes(
          [pupukLab],
          aktivitas(data(kirimLab: '2026-10-01', registrasiLab: '2026-10-02')),
        ),
        isEmpty,
        reason: 'already received',
      );
      expect(
        allowedPupukActivityTypes([pupukLab], aktivitas(data(kirimLab: ''))),
        isEmpty,
        reason: 'blank date counts as unset',
      );
    });

    test('a local receipt holding the code hides Terima Lab', () {
      final sent = data(kirimLab: '2026-10-01');
      expect(
        allowedPupukActivityTypes(
          [pupukLab],
          aktivitas(sent),
          pendingPupukLabKodes: {'BATCH'},
        ),
        isEmpty,
      );
      expect(
        allowedPupukActivityTypes(
          [pupukLab],
          aktivitas(sent),
          pendingPupukLabKodes: {'OTHER'},
        ),
        [kPupukLab],
      );
    });

    test('without the permission Terima Lab never shows', () {
      final sent = data(kirimLab: '2026-10-01');
      expect(allowedPupukActivityTypes([estate], aktivitas(sent)), [
        kKirimDariEstate,
      ]);
    });

    test('works from the synced record when no activity row exists', () {
      expect(
        allowedPupukActivityTypes(
          [pupukLab],
          null,
          dataSampelPupukFallback: data(kirimLab: '2026-10-01'),
        ),
        [kPupukLab],
      );
      expect(allowedPupukActivityTypes([pupukLab], null), isEmpty);
    });

    test('Kirim Lab and Kirim dari Estate follow photo and local rows', () {
      final fresh = data();
      expect(allowedPupukActivityTypes([estate, lab], aktivitas(fresh)), [
        kKirimDariEstate,
        kKirimLab,
      ]);

      final labPhoto = data(fotoKirimLab: '/p.jpg');
      expect(allowedPupukActivityTypes([estate, lab], aktivitas(labPhoto)), [
        kKirimDariEstate,
      ]);

      final localLab = KirimLab(
        dataSampelPupukId: 1,
        kodeSampel: 'BATCH',
        tanggalKirimLab: '2026-10-01',
        createdAt: '2026-10-01T08:00:00',
      );
      expect(
        allowedPupukActivityTypes([
          estate,
          lab,
        ], aktivitas(fresh, kirimLab: localLab)),
        [kKirimDariEstate],
      );
    });
  });

  group('allowedPupukActivityTypes for an individual kode', () {
    final batch = data(
      trackingJson: tracking([
        ['A', 'SRS/1', '2026-09-30', '2026-10-01', null, null],
        ['B', 'SRS/1', '2026-09-30', '2026-10-01', '2026-10-02', null],
        ['C', null, '2026-09-30', null, null, null],
        ['D', 'SRS/2', null, null, null, null],
      ]),
    );

    List<String> allowed(String kode, {Set<String> reserved = const {}}) =>
        allowedPupukActivityTypes(
          [estate, lab, pupukLab],
          aktivitas(batch),
          individualKodeSampel: kode,
          pendingPupukLabKodes: reserved,
        );

    test('sent to lab and not received: only Terima Lab', () {
      expect(allowed('A'), [kPupukLab]);
    });

    test('already received at the lab: nothing left', () {
      expect(allowed('B'), isEmpty);
    });

    test('sent from estate but not to the lab: Kirim Lab only', () {
      expect(allowed('C'), [kKirimLab]);
    });

    test('untouched code: the two Kirim types', () {
      expect(allowed('D'), [kKirimDariEstate, kKirimLab]);
    });

    test('a code missing from tracking is not eligible for Terima Lab', () {
      expect(allowed('Z'), [kKirimDariEstate, kKirimLab]);
    });

    test('a local receipt reserves the individual code', () {
      expect(allowed('A', reserved: {'A'}), isEmpty);
      expect(allowed('A', reserved: {'B'}), [kPupukLab]);
    });

    test('records without tracking fall back to the record columns', () {
      final plain = data(kirimLab: '2026-10-01');
      expect(
        allowedPupukActivityTypes(
          [pupukLab],
          aktivitas(plain),
          individualKodeSampel: 'BATCH',
        ),
        [kPupukLab],
      );
    });

    test('malformed tracking never throws and never offers Terima Lab', () {
      final broken = data(trackingJson: '{not json');
      expect(
        allowedPupukActivityTypes(
          [pupukLab],
          aktivitas(broken),
          individualKodeSampel: 'A',
        ),
        isEmpty,
      );
    });
  });

  group('isEligibleForPupukLab', () {
    test('null data is not eligible', () {
      expect(isEligibleForPupukLab(null), isFalse);
    });

    test('short tracking tuples are handled', () {
      final short = data(
        trackingJson: tracking([
          ['A', 'S'],
          ['B', 'S', null, '2026-10-01'],
        ]),
      );
      expect(isEligibleForPupukLab(short, individualKodeSampel: 'A'), isFalse);
      expect(isEligibleForPupukLab(short, individualKodeSampel: 'B'), isTrue);
    });
  });
}
