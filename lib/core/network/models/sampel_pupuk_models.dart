import '../../database/models/data_sampel_pupuk.dart';
import 'auth_models.dart';

class PaginatedDataSampelPupukResponse {
  final List<DataSampelPupuk> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedDataSampelPupukResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedDataSampelPupukResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'];
    final items = list is List
        ? list
              .map(
                (e) => DataSampelPupuk.fromApiJson(e as Map<String, dynamic>),
              )
              .toList()
        : <DataSampelPupuk>[];
    return PaginatedDataSampelPupukResponse(
      data: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Sync response: dataSampelPupuk list + optional user (when auth sent).
class SyncSampelPupukResponse {
  final List<DataSampelPupukDto> dataSampelPupuk;
  final User? user;

  SyncSampelPupukResponse({required this.dataSampelPupuk, this.user});

  factory SyncSampelPupukResponse.fromJson(Map<String, dynamic> json) {
    final list = json['dataSampelPupuk'];
    final List<DataSampelPupukDto> items = list is List
        ? list
              .map(
                (e) => DataSampelPupukDto.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : [];
    User? user;
    if (json['user'] != null) {
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    }
    return SyncSampelPupukResponse(dataSampelPupuk: items, user: user);
  }
}

/// Single item from sync dataSampelPupuk (API payload).
class DataSampelPupukDto {
  final int id;
  final String? kodeSampel;
  final String? jenisPupukFull;
  final String? jenisPupuk;
  final String? merek;
  final int? noKodeSampel;
  final int? jumlahSampelZak;
  final String? noSegel;
  final String? noBaSampelPupuk;
  final String? supplier;
  final int? regional;
  final int? wilayah;
  final String? estate;
  final String? pt;
  final String? noPo;
  final String? noBpb;
  final int? qtyPartaiPengiriman;
  final int? qtyTerima;
  final String? jenisKendaraan;
  final String? tanggalPengambilanSampel;
  final String? checkLogoPerusahaan;
  final String? checkKondisiKarung;
  final String? checkJahitanKarung;
  final String? checkKontaminan;
  final String? checkJenisKontaminan;
  final String? checkPersentaseKontaminan;
  final String? checkBekasGancu;
  final String? diperiksaEstateManagerNama;
  final String? diperiksaKtuNama;
  final String? disaksikanSupplierNama;
  final String? diambilKepalaGudang;
  final String? tanggalKirimDariEstate;
  final String? fotoKirimDariEstate;
  final String? namaPengirim;
  final String? noSurat;
  final String? tanggalKirimLab;
  final String? fotoKirimLab;
  final String? tanggalRegistrasiLab;
  final String? fotoRegistrasiLab;
  final String? tanggalEstimasiKupa;
  final String? kodeTracking;
  final String? noSertifikat;
  final String? tanggalKirimSertifikatEstate;
  final String? rekomendasi;
  final String? createdAt;
  final String? updatedAt;

  DataSampelPupukDto({
    required this.id,
    this.kodeSampel,
    this.jenisPupukFull,
    this.jenisPupuk,
    this.merek,
    this.noKodeSampel,
    this.jumlahSampelZak,
    this.noSegel,
    this.noBaSampelPupuk,
    this.supplier,
    this.regional,
    this.wilayah,
    this.estate,
    this.pt,
    this.noPo,
    this.noBpb,
    this.qtyPartaiPengiriman,
    this.qtyTerima,
    this.jenisKendaraan,
    this.tanggalPengambilanSampel,
    this.checkLogoPerusahaan,
    this.checkKondisiKarung,
    this.checkJahitanKarung,
    this.checkKontaminan,
    this.checkJenisKontaminan,
    this.checkPersentaseKontaminan,
    this.checkBekasGancu,
    this.diperiksaEstateManagerNama,
    this.diperiksaKtuNama,
    this.disaksikanSupplierNama,
    this.diambilKepalaGudang,
    this.tanggalKirimDariEstate,
    this.fotoKirimDariEstate,
    this.namaPengirim,
    this.noSurat,
    this.tanggalKirimLab,
    this.fotoKirimLab,
    this.tanggalRegistrasiLab,
    this.fotoRegistrasiLab,
    this.tanggalEstimasiKupa,
    this.kodeTracking,
    this.noSertifikat,
    this.tanggalKirimSertifikatEstate,
    this.rekomendasi,
    this.createdAt,
    this.updatedAt,
  });

  factory DataSampelPupukDto.fromJson(Map<String, dynamic> json) {
    return DataSampelPupukDto(
      id: json['id'] as int,
      kodeSampel: json['kodeSampel'] as String?,
      jenisPupukFull: json['jenisPupukFull'] as String?,
      jenisPupuk: json['jenisPupuk'] as String?,
      merek: json['merek'] as String?,
      noKodeSampel: (json['noKodeSampel'] as num?)?.toInt(),
      jumlahSampelZak: (json['jumlahSampelZak'] as num?)?.toInt(),
      noSegel: json['noSegel'] as String?,
      noBaSampelPupuk: json['noBaSampelPupuk'] as String?,
      supplier: json['supplier'] as String?,
      regional: (json['regional'] as num?)?.toInt(),
      wilayah: (json['wilayah'] as num?)?.toInt(),
      estate: json['estate'] as String?,
      pt: json['pt'] as String?,
      noPo: json['noPo'] as String?,
      noBpb: json['noBpb'] as String?,
      qtyPartaiPengiriman: (json['qtyPartaiPengiriman'] as num?)?.toInt(),
      qtyTerima: (json['qtyTerima'] as num?)?.toInt(),
      jenisKendaraan: json['jenisKendaraan'] as String?,
      tanggalPengambilanSampel: json['tanggalPengambilanSampel'] as String?,
      checkLogoPerusahaan: json['checkLogoPerusahaan'] as String?,
      checkKondisiKarung: json['checkKondisiKarung'] as String?,
      checkJahitanKarung: json['checkJahitanKarung'] as String?,
      checkKontaminan: json['checkKontaminan'] as String?,
      checkJenisKontaminan: json['checkJenisKontaminan'] as String?,
      checkPersentaseKontaminan: json['checkPersentaseKontaminan'] as String?,
      checkBekasGancu: json['checkBekasGancu'] as String?,
      diperiksaEstateManagerNama: json['diperiksaEstateManagerNama'] as String?,
      diperiksaKtuNama: json['diperiksaKtuNama'] as String?,
      disaksikanSupplierNama: json['disaksikanSupplierNama'] as String?,
      diambilKepalaGudang: json['diambilKepalaGudang'] as String?,
      tanggalKirimDariEstate: json['tanggalKirimDariEstate'] as String?,
      fotoKirimDariEstate: json['fotoKirimDariEstate'] as String?,
      namaPengirim: json['namaPengirim'] as String?,
      noSurat: json['noSurat'] as String?,
      tanggalKirimLab: json['tanggalKirimLab'] as String?,
      fotoKirimLab: json['fotoKirimLab'] as String?,
      tanggalRegistrasiLab: json['tanggalRegistrasiLab'] as String?,
      fotoRegistrasiLab: json['fotoRegistrasiLab'] as String?,
      tanggalEstimasiKupa: json['tanggalEstimasiKupa'] as String?,
      kodeTracking: json['kodeTracking'] as String?,
      noSertifikat: json['noSertifikat'] as String?,
      tanggalKirimSertifikatEstate:
          json['tanggalKirimSertifikatEstate'] as String?,
      rekomendasi: json['rekomendasi'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kodeSampel': kodeSampel,
      'jenisPupukFull': jenisPupukFull,
      'jenisPupuk': jenisPupuk,
      'merek': merek,
      'noKodeSampel': noKodeSampel,
      'jumlahSampelZak': jumlahSampelZak,
      'noSegel': noSegel,
      'noBaSampelPupuk': noBaSampelPupuk,
      'supplier': supplier,
      'regional': regional,
      'wilayah': wilayah,
      'estate': estate,
      'pt': pt,
      'noPo': noPo,
      'noBpb': noBpb,
      'qtyPartaiPengiriman': qtyPartaiPengiriman,
      'qtyTerima': qtyTerima,
      'jenisKendaraan': jenisKendaraan,
      'tanggalPengambilanSampel': tanggalPengambilanSampel,
      'checkLogoPerusahaan': checkLogoPerusahaan,
      'checkKondisiKarung': checkKondisiKarung,
      'checkJahitanKarung': checkJahitanKarung,
      'checkKontaminan': checkKontaminan,
      'checkJenisKontaminan': checkJenisKontaminan,
      'checkPersentaseKontaminan': checkPersentaseKontaminan,
      'checkBekasGancu': checkBekasGancu,
      'diperiksaEstateManagerNama': diperiksaEstateManagerNama,
      'diperiksaKtuNama': diperiksaKtuNama,
      'disaksikanSupplierNama': disaksikanSupplierNama,
      'diambilKepalaGudang': diambilKepalaGudang,
      'tanggalKirimDariEstate': tanggalKirimDariEstate,
      'fotoKirimDariEstate': fotoKirimDariEstate,
      'namaPengirim': namaPengirim,
      'noSurat': noSurat,
      'tanggalKirimLab': tanggalKirimLab,
      'fotoKirimLab': fotoKirimLab,
      'tanggalRegistrasiLab': tanggalRegistrasiLab,
      'fotoRegistrasiLab': fotoRegistrasiLab,
      'tanggalEstimasiKupa': tanggalEstimasiKupa,
      'kodeTracking': kodeTracking,
      'noSertifikat': noSertifikat,
      'tanggalKirimSertifikatEstate': tanggalKirimSertifikatEstate,
      'rekomendasi': rekomendasi,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// --- Area API responses ---

class AreaRegionalResponse {
  final List<int> data;

  AreaRegionalResponse({required this.data});

  factory AreaRegionalResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'];
    if (list is List) {
      return AreaRegionalResponse(
        data: list.map((e) => (e as num).toInt()).toList(),
      );
    }
    return AreaRegionalResponse(data: []);
  }
}

class AreaWilayahResponse {
  final List<int> data;

  AreaWilayahResponse({required this.data});

  factory AreaWilayahResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'];
    if (list is List) {
      return AreaWilayahResponse(
        data: list.map((e) => (e as num).toInt()).toList(),
      );
    }
    return AreaWilayahResponse(data: []);
  }
}

class EstateItem {
  final int id;
  final int regional;
  final int wilayah;
  final String abbr;
  final String nama;

  EstateItem({
    required this.id,
    required this.regional,
    required this.wilayah,
    required this.abbr,
    required this.nama,
  });

  factory EstateItem.fromJson(Map<String, dynamic> json) {
    return EstateItem(
      id: json['id'] as int,
      regional: (json['regional'] as num).toInt(),
      wilayah: (json['wilayah'] as num).toInt(),
      abbr: json['abbr'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
    );
  }
}

class AreaEstateResponse {
  final List<EstateItem> data;
  final int total;

  AreaEstateResponse({required this.data, required this.total});

  factory AreaEstateResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'];
    if (list is List) {
      return AreaEstateResponse(
        data: list
            .map((e) => EstateItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? list.length,
      );
    }
    return AreaEstateResponse(data: [], total: 0);
  }
}

// --- Upload request (activity payload) ---

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

class SampelPupukUploadPayload {
  final List<KirimDariEstateItem> kirimDariEstate;
  final List<KirimLabItem> kirimLab;
  final List<KirimSertifikatEstateItem> kirimSertifikatEstate;

  SampelPupukUploadPayload({
    this.kirimDariEstate = const [],
    this.kirimLab = const [],
    this.kirimSertifikatEstate = const [],
  });

  Map<String, dynamic> toJson() => {
    'kirimDariEstate': kirimDariEstate.map((e) => e.toJson()).toList(),
    'kirimLab': kirimLab.map((e) => e.toJson()).toList(),
    'kirimSertifikatEstate': kirimSertifikatEstate
        .map((e) => e.toJson())
        .toList(),
  };
}

// --- Upload response (success/failed per type) ---

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

class UploadSuccessItem {
  final int id;

  UploadSuccessItem({required this.id});

  factory UploadSuccessItem.fromJson(Map<String, dynamic> json) {
    return UploadSuccessItem(id: json['id'] as int);
  }
}

class UploadFailedItem {
  final int id;
  final String error;

  UploadFailedItem({required this.id, required this.error});

  factory UploadFailedItem.fromJson(Map<String, dynamic> json) {
    return UploadFailedItem(
      id: json['id'] as int,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }
}

class SampelPupukUploadResponse {
  final UploadTypeResult kirimDariEstate;
  final UploadTypeResult kirimLab;
  final UploadTypeResult kirimSertifikatEstate;

  SampelPupukUploadResponse({
    required this.kirimDariEstate,
    required this.kirimLab,
    required this.kirimSertifikatEstate,
  });

  factory SampelPupukUploadResponse.fromJson(Map<String, dynamic> json) {
    return SampelPupukUploadResponse(
      kirimDariEstate: UploadTypeResult.fromJson(
        json['kirimDariEstate'] as Map<String, dynamic>? ?? {},
      ),
      kirimLab: UploadTypeResult.fromJson(
        json['kirimLab'] as Map<String, dynamic>? ?? {},
      ),
      kirimSertifikatEstate: UploadTypeResult.fromJson(
        json['kirimSertifikatEstate'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

// --- Photo upload response ---

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

class NextNoSuratResponse {
  final String noSurat;
  final int sequence;

  NextNoSuratResponse({required this.noSurat, required this.sequence});

  factory NextNoSuratResponse.fromJson(Map<String, dynamic> json) {
    return NextNoSuratResponse(
      noSurat: json['noSurat'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
    );
  }
}
