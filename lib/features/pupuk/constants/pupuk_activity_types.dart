import 'dart:convert';
import 'package:sampletrack/core/constants/permission_constants.dart';
import 'package:sampletrack/core/database/models/aktivitas_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';

/// Activity type keys for Sampel Pupuk
const String kKirimDariEstate = 'kirimDariEstate';
const String kKirimLab = 'kirimLab';
const String kKirimSertifikatEstate = 'kirimSertifikatEstate';

const List<String> kAllPupukActivityTypes = [
  kKirimDariEstate,
  kKirimLab,
  kKirimSertifikatEstate,
];

String labelForPupukActivityType(String type) {
  switch (type) {
    case kKirimDariEstate:
      return 'Kirim dari Estate';
    case kKirimLab:
      return 'Kirim Lab';
    case kKirimSertifikatEstate:
      return 'Kirim Sertifikat';
    default:
      return type;
  }
}

/// Returns activity types allowed for user permissions and record state.
List<String> allowedPupukActivityTypes(
  List<String>? permissions,
  AktivitasSampelPupuk? aktivitasSampelPupuk, {
  DataSampelPupuk? dataSampelPupukFallback,
  String? individualKodeSampel,
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

    if (data?.trackingSampelPupuk != null) {
      try {
        final List<dynamic> trackingList = jsonDecode(
          data!.trackingSampelPupuk!,
        );
        final entry = trackingList.firstWhere(
          (item) =>
              item is List &&
              item.isNotEmpty &&
              item[0] == individualKodeSampel,
          orElse: () => null,
        );
        if (entry != null) {
          final String? waktuKirimEstate = entry.length > 2
              ? entry[2] as String?
              : null;
          final String? waktuKirimLab = entry.length > 3
              ? entry[3] as String?
              : null;

          canKirimDariEstate =
              canKirimDariEstate &&
              (waktuKirimEstate == null || waktuKirimEstate.isEmpty);
          canKirimLab =
              canKirimLab && (waktuKirimLab == null || waktuKirimLab.isEmpty);
        }
      } catch (e) {
        // fallback
      }
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
  return list;
}
