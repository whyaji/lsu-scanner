import 'dart:convert';
import 'package:sampletrack/core/constants/permission_constants.dart';
import 'package:sampletrack/core/database/models/aktivitas_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';

/// Activity type keys for Sampel Pupuk. They double as the keys of the upload
/// payload and response.
const String kKirimDariEstate = 'kirimDariEstate';
const String kKirimLab = 'kirimLab';
const String kKirimSertifikatEstate = 'kirimSertifikatEstate';
const String kPupukLab = 'pupukLab';

/// Types sent by `POST /data-sampel-pupuk/upload`, in upload order.
const List<String> kUploadablePupukActivityTypes = [
  kKirimDariEstate,
  kKirimLab,
  kKirimSertifikatEstate,
  kPupukLab,
];

String labelForPupukActivityType(String type) {
  switch (type) {
    case kKirimDariEstate:
      return 'Kirim dari Estate';
    case kKirimLab:
      return 'Kirim Lab';
    case kKirimSertifikatEstate:
      return 'Kirim Sertifikat';
    case kPupukLab:
      return 'Terima Lab';
    default:
      return type;
  }
}

/// One entry of `trackingSampelPupuk`:
/// `[kode, noSurat, kirimEstate, kirimLab, registrasiLab, estimasiKupa, ...]`.
List<dynamic>? _trackingEntry(DataSampelPupuk? data, String kode) {
  final raw = data?.trackingSampelPupuk;
  if (raw == null) return null;
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    for (final item in list) {
      if (item is List && item.isNotEmpty && item[0] == kode) return item;
    }
  } catch (_) {
    return null;
  }
  return null;
}

bool _isSet(Object? value) => value is String && value.isNotEmpty;

/// Why a sample can or cannot be received at the lab.
enum PupukLabEligibility {
  eligible,

  /// The record or the code is not on this device (sync first).
  notFound,

  /// Kirim Lab has not been recorded, so the sample is not on its way yet.
  notSentToLab,

  /// The server already shows the sample as received.
  alreadyReceived,

  /// A local Terima Lab receipt already holds the code.
  reservedLocally,
}

/// Decides whether the lab can still receive this sample: Kirim Lab is done,
/// Terima Lab is not, and no local Terima Lab receipt already holds the code.
///
/// [pendingPupukLabKodes] are the codes in local `pupuk_lab` rows
/// (`PupukLabDao.getReservedKodeSampel`). With [individualKodeSampel] the
/// per-code tracking tuple decides; otherwise the record columns do.
PupukLabEligibility pupukLabEligibility(
  DataSampelPupuk? data, {
  String? individualKodeSampel,
  Set<String> pendingPupukLabKodes = const {},
}) {
  if (data == null) return PupukLabEligibility.notFound;
  final kode = individualKodeSampel ?? data.kodeSampel;

  PupukLabEligibility? fromState({
    required Object? kirimLab,
    required Object? registrasiLab,
  }) {
    if (!_isSet(kirimLab)) return PupukLabEligibility.notSentToLab;
    if (_isSet(registrasiLab)) return PupukLabEligibility.alreadyReceived;
    return null;
  }

  PupukLabEligibility? blocked;
  if (individualKodeSampel != null && data.trackingSampelPupuk != null) {
    final entry = _trackingEntry(data, individualKodeSampel);
    if (entry == null) return PupukLabEligibility.notFound;
    blocked = fromState(
      kirimLab: entry.length > 3 ? entry[3] : null,
      registrasiLab: entry.length > 4 ? entry[4] : null,
    );
  } else {
    blocked = fromState(
      kirimLab: data.tanggalKirimLab,
      registrasiLab: data.tanggalRegistrasiLab,
    );
  }
  if (blocked != null) return blocked;
  if (kode != null && pendingPupukLabKodes.contains(kode)) {
    return PupukLabEligibility.reservedLocally;
  }
  return PupukLabEligibility.eligible;
}

bool isEligibleForPupukLab(
  DataSampelPupuk? data, {
  String? individualKodeSampel,
  Set<String> pendingPupukLabKodes = const {},
}) =>
    pupukLabEligibility(
      data,
      individualKodeSampel: individualKodeSampel,
      pendingPupukLabKodes: pendingPupukLabKodes,
    ) ==
    PupukLabEligibility.eligible;

/// No. surat of one sample: the per-code tracking tuple (set at Kirim Lab)
/// first, then the record column.
String? pupukSampleNoSurat(DataSampelPupuk? data, String kodeSampel) {
  final entry = _trackingEntry(data, kodeSampel);
  final fromTuple = entry != null && entry.length > 1 ? entry[1] : null;
  if (_isSet(fromTuple)) return (fromTuple as String).trim();
  final fromRecord = data?.noSurat?.trim();
  return (fromRecord == null || fromRecord.isEmpty) ? null : fromRecord;
}

/// Returns activity types allowed for user permissions and record state.
List<String> allowedPupukActivityTypes(
  List<String>? permissions,
  AktivitasSampelPupuk? aktivitasSampelPupuk, {
  DataSampelPupuk? dataSampelPupukFallback,
  String? individualKodeSampel,
  Set<String> pendingPupukLabKodes = const {},
}) {
  final DataSampelPupuk? data =
      aktivitasSampelPupuk?.dataSampelPupuk ?? dataSampelPupukFallback;

  bool canKirimLab =
      aktivitasSampelPupuk?.kirimLab == null && data?.fotoKirimLab == null;
  bool canKirimDariEstate =
      aktivitasSampelPupuk?.kirimDariEstate == null &&
      data?.fotoKirimDariEstate == null;

  if (individualKodeSampel != null) {
    canKirimLab = aktivitasSampelPupuk?.kirimLab == null;
    canKirimDariEstate = aktivitasSampelPupuk?.kirimDariEstate == null;

    final entry = _trackingEntry(data, individualKodeSampel);
    if (entry != null) {
      final waktuKirimEstate = entry.length > 2 ? entry[2] : null;
      final waktuKirimLab = entry.length > 3 ? entry[3] : null;
      canKirimDariEstate = canKirimDariEstate && !_isSet(waktuKirimEstate);
      canKirimLab = canKirimLab && !_isSet(waktuKirimLab);
    }
  }

  if (permissions == null || permissions.isEmpty) return [];
  final list = <String>[];
  if (permissions.contains(PermissionConstants.pupukMobileKirimEstate) &&
      canKirimDariEstate) {
    list.add(kKirimDariEstate);
  }
  if (permissions.contains(PermissionConstants.pupukMobileKirimLab) &&
      canKirimLab) {
    list.add(kKirimLab);
  }
  if (permissions.contains(PermissionConstants.pupukMobilePupukLab) &&
      isEligibleForPupukLab(
        data,
        individualKodeSampel: individualKodeSampel,
        pendingPupukLabKodes: pendingPupukLabKodes,
      )) {
    list.add(kPupukLab);
  }
  return list;
}

/// Activity types shown on home (QR scan shortcuts).
List<String> homePupukActivityTypes(List<String>? permissions) {
  if (permissions == null || permissions.isEmpty) return [];
  final list = <String>[];
  if (permissions.contains(PermissionConstants.pupukMobileKirimEstate)) {
    list.add(kKirimDariEstate);
  }
  if (permissions.contains(PermissionConstants.pupukMobileKirimLab)) {
    list.add(kKirimLab);
  }
  if (permissions.contains(PermissionConstants.pupukMobilePupukLab)) {
    list.add(kPupukLab);
  }
  return list;
}
