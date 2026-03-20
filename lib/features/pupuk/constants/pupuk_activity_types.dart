import 'package:sampletrack/core/database/models/aktivitas_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';

/// Activity type keys for Sampel Pupuk (must match API: terimaDariGudang, etc.)
const String kTerimaDariGudang = 'terimaDariGudang';
const String kKirimDariEstate = 'kirimDariEstate';
const String kTerimaDariEstate = 'terimaDariEstate';
const String kKirimLab = 'kirimLab';
const String kKirimSertifikatEstate = 'kirimSertifikatEstate';

const List<String> kAllPupukActivityTypes = [
  kTerimaDariGudang,
  kKirimDariEstate,
  kTerimaDariEstate,
  kKirimLab,
  kKirimSertifikatEstate,
];

String labelForPupukActivityType(String type) {
  switch (type) {
    case kTerimaDariGudang:
      return 'Terima dari Gudang';
    case kKirimDariEstate:
      return 'Kirim dari Estate';
    case kTerimaDariEstate:
      return 'Terima dari Estate';
    case kKirimLab:
      return 'Kirim Lab';
    case kKirimSertifikatEstate:
      return 'Kirim Sertifikat';
    default:
      return type;
  }
}

/// Returns activity types allowed for user with given access list.
///
/// [dataSampelPupukFallback] is used for synced foto/tanggal fields when
/// [aktivitasSampelPupuk] is null (e.g. QR-only flow). Local activity rows
/// still require [aktivitasSampelPupuk] to be loaded from the DB.
List<String> allowedPupukActivityTypes(
  List<String>? access,
  AktivitasSampelPupuk? aktivitasSampelPupuk, {
  DataSampelPupuk? dataSampelPupukFallback,
}) {
  final DataSampelPupuk? data =
      aktivitasSampelPupuk?.dataSampelPupuk ?? dataSampelPupukFallback;

  final bool canTerimaDariGudang =
      aktivitasSampelPupuk?.terimaDariGudang == null &&
      data?.fotoTerimaDariGudang == null;
  final bool canKirimDariEstate =
      aktivitasSampelPupuk?.kirimDariEstate == null &&
      data?.fotoKirimDariEstate == null;
  final bool canTerimaDariEstate =
      aktivitasSampelPupuk?.terimaDariEstate == null &&
      data?.fotoTerimaDariEstate == null;
  final bool canKirimLab =
      aktivitasSampelPupuk?.kirimLab == null && data?.fotoKirimLab == null;

  if (access == null || access.isEmpty) return [];
  final list = <String>[];
  if (access.contains('pupuk:estate')) {
    if (canTerimaDariGudang) list.add(kTerimaDariGudang);
    if (canKirimDariEstate) list.add(kKirimDariEstate);
  }
  if (access.contains('pupuk:nt')) {
    if (canTerimaDariEstate) list.add(kTerimaDariEstate);
    if (canKirimLab) list.add(kKirimLab);
  }
  return list;
}
