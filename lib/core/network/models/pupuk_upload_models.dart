import '../../../features/pupuk/constants/pupuk_activity_types.dart';
import '../../../features/pupuk_lab/models/pupuk_lab_upload.dart';
import 'upload_models.dart';

class KirimDariEstateItem {
  final int id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String tanggalKirimDariEstate;
  final String? fotoKirimDariEstate;
  final String? namaPengirim;

  KirimDariEstateItem({
    required this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    required this.tanggalKirimDariEstate,
    this.fotoKirimDariEstate,
    this.namaPengirim,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataSampelPupukId': dataSampelPupukId,
    'kodeSampel': kodeSampel,
    'tanggalKirimDariEstate': tanggalKirimDariEstate,
    if (fotoKirimDariEstate != null) 'fotoKirimDariEstate': fotoKirimDariEstate,
    if (namaPengirim != null) 'namaPengirim': namaPengirim,
  };
}

class KirimLabItem {
  final int id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String? noSurat;
  final String tanggalKirimLab;
  final String? fotoKirimLab;

  KirimLabItem({
    required this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    this.noSurat,
    required this.tanggalKirimLab,
    this.fotoKirimLab,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataSampelPupukId': dataSampelPupukId,
    'kodeSampel': kodeSampel,
    if (noSurat != null) 'noSurat': noSurat,
    'tanggalKirimLab': tanggalKirimLab,
    if (fotoKirimLab != null) 'fotoKirimLab': fotoKirimLab,
  };
}

class KirimSertifikatEstateItem {
  final int id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String tanggalKirimSertifikatEstate;
  final String rekomendasi;
  final String fileSertifikat;

  KirimSertifikatEstateItem({
    required this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    required this.tanggalKirimSertifikatEstate,
    required this.rekomendasi,
    required this.fileSertifikat,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataSampelPupukId': dataSampelPupukId,
    'kodeSampel': kodeSampel,
    'tanggalKirimSertifikatEstate': tanggalKirimSertifikatEstate,
    'rekomendasi': rekomendasi,
    'fileSertifikat': fileSertifikat,
  };
}

/// Body of `POST /data-sampel-pupuk/upload`: JSON items per activity type key.
/// Every type key is always sent, as an empty list when nothing is pending.
class SampelPupukUploadPayload {
  const SampelPupukUploadPayload(this.itemsByType);

  final Map<String, List<Map<String, dynamic>>> itemsByType;

  Map<String, dynamic> toJson() => {
    for (final type in kUploadablePupukActivityTypes)
      type: itemsByType[type] ?? const <Map<String, dynamic>>[],
  };
}

/// Per-type outcome for the three status-only types (id, plus error text).
class UploadTypeResult {
  final List<UploadSuccessItem> success;
  final List<UploadFailedItem> failed;

  UploadTypeResult({required this.success, required this.failed});

  factory UploadTypeResult.fromJson(Map<String, dynamic> json) {
    final successList = json['success'];
    final failedList = json['failed'];
    return UploadTypeResult(
      success: successList is List
          ? successList
                .map(
                  (e) => UploadSuccessItem.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
      failed: failedList is List
          ? failedList
                .map(
                  (e) => UploadFailedItem.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

class SampelPupukUploadResponse {
  final UploadTypeResult kirimDariEstate;
  final UploadTypeResult kirimLab;
  final UploadTypeResult kirimSertifikatEstate;
  final PupukLabUploadResult pupukLab;

  SampelPupukUploadResponse({
    required this.kirimDariEstate,
    required this.kirimLab,
    required this.kirimSertifikatEstate,
    this.pupukLab = const PupukLabUploadResult(),
  });

  factory SampelPupukUploadResponse.fromJson(Map<String, dynamic> json) {
    UploadTypeResult typed(String key) => UploadTypeResult.fromJson(
      json[key] as Map<String, dynamic>? ?? const {},
    );
    return SampelPupukUploadResponse(
      kirimDariEstate: typed(kKirimDariEstate),
      kirimLab: typed(kKirimLab),
      kirimSertifikatEstate: typed(kKirimSertifikatEstate),
      pupukLab: PupukLabUploadResult.fromJson(
        json[kPupukLab] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PhotoPupukUploadResponse {
  final String filePath;
  final String type;

  PhotoPupukUploadResponse({required this.filePath, required this.type});

  factory PhotoPupukUploadResponse.fromJson(Map<String, dynamic> json) {
    return PhotoPupukUploadResponse(
      filePath: json['filePath'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}
