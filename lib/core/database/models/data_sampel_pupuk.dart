/// Local mirror of sync payload for Data Sampel Pupuk (lookup by id after QR scan).
class DataSampelPupuk {
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
  final String? tanggalTerimaDariGudang;
  final String? fotoTerimaDariGudang;
  final String? tanggalKirimDariEstate;
  final String? fotoKirimDariEstate;
  final String? tanggalTerimaDariEstate;
  final String? fotoTerimaDariEstate;
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

  DataSampelPupuk({
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
    this.tanggalTerimaDariGudang,
    this.fotoTerimaDariGudang,
    this.tanggalKirimDariEstate,
    this.fotoKirimDariEstate,
    this.tanggalTerimaDariEstate,
    this.fotoTerimaDariEstate,
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

  factory DataSampelPupuk.fromApiJson(Map<String, dynamic> json) {
    return DataSampelPupuk(
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
      tanggalTerimaDariGudang: json['tanggalTerimaDariGudang'] as String?,
      fotoTerimaDariGudang: json['fotoTerimaDariGudang'] as String?,
      tanggalKirimDariEstate: json['tanggalKirimDariEstate'] as String?,
      fotoKirimDariEstate: json['fotoKirimDariEstate'] as String?,
      tanggalTerimaDariEstate: json['tanggalTerimaDariEstate'] as String?,
      fotoTerimaDariEstate: json['fotoTerimaDariEstate'] as String?,
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

  factory DataSampelPupuk.fromJson(Map<String, dynamic> json) {
    return DataSampelPupuk(
      id: json['id'] as int,
      kodeSampel: json['kode_sampel'] as String?,
      jenisPupukFull: json['jenis_pupuk_full'] as String?,
      jenisPupuk: json['jenis_pupuk'] as String?,
      merek: json['merek'] as String?,
      noKodeSampel: (json['no_kode_sampel'] as num?)?.toInt(),
      jumlahSampelZak: (json['jumlah_sampel_zak'] as num?)?.toInt(),
      noSegel: json['no_segel'] as String?,
      noBaSampelPupuk: json['no_ba_sampel_pupuk'] as String?,
      supplier: json['supplier'] as String?,
      regional: (json['regional'] as num?)?.toInt(),
      wilayah: (json['wilayah'] as num?)?.toInt(),
      estate: json['estate'] as String?,
      pt: json['pt'] as String?,
      noPo: json['no_po'] as String?,
      noBpb: json['no_bpb'] as String?,
      qtyPartaiPengiriman: (json['qty_partai_pengiriman'] as num?)?.toInt(),
      qtyTerima: (json['qty_terima'] as num?)?.toInt(),
      jenisKendaraan: json['jenis_kendaraan'] as String?,
      tanggalPengambilanSampel: json['tanggal_pengambilan_sampel'] as String?,
      checkLogoPerusahaan: json['check_logo_perusahaan'] as String?,
      checkKondisiKarung: json['check_kondisi_karung'] as String?,
      checkJahitanKarung: json['check_jahitan_karung'] as String?,
      checkKontaminan: json['check_kontaminan'] as String?,
      checkJenisKontaminan: json['check_jenis_kontaminan'] as String?,
      checkPersentaseKontaminan: json['check_persentase_kontaminan'] as String?,
      checkBekasGancu: json['check_bekas_gancu'] as String?,
      diperiksaEstateManagerNama:
          json['diperiksa_estate_manager_nama'] as String?,
      diperiksaKtuNama: json['diperiksa_ktu_nama'] as String?,
      disaksikanSupplierNama: json['disaksikan_supplier_nama'] as String?,
      diambilKepalaGudang: json['diambil_kepala_gudang'] as String?,
      tanggalTerimaDariGudang: json['tanggal_terima_dari_gudang'] as String?,
      fotoTerimaDariGudang: json['foto_terima_dari_gudang'] as String?,
      tanggalKirimDariEstate: json['tanggal_kirim_dari_estate'] as String?,
      fotoKirimDariEstate: json['foto_kirim_dari_estate'] as String?,
      tanggalTerimaDariEstate: json['tanggal_terima_dari_estate'] as String?,
      fotoTerimaDariEstate: json['foto_terima_dari_estate'] as String?,
      namaPengirim: json['nama_pengirim'] as String?,
      noSurat: json['no_surat'] as String?,
      tanggalKirimLab: json['tanggal_kirim_lab'] as String?,
      fotoKirimLab: json['foto_kirim_lab'] as String?,
      tanggalRegistrasiLab: json['tanggal_registrasi_lab'] as String?,
      fotoRegistrasiLab: json['foto_registrasi_lab'] as String?,
      tanggalEstimasiKupa: json['tanggal_estimasi_kupa'] as String?,
      kodeTracking: json['kode_tracking'] as String?,
      noSertifikat: json['no_sertifikat'] as String?,
      tanggalKirimSertifikatEstate:
          json['tanggal_kirim_sertifikat_estate'] as String?,
      rekomendasi: json['rekomendasi'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_sampel': kodeSampel,
      'jenis_pupuk_full': jenisPupukFull,
      'jenis_pupuk': jenisPupuk,
      'merek': merek,
      'no_kode_sampel': noKodeSampel,
      'jumlah_sampel_zak': jumlahSampelZak,
      'no_segel': noSegel,
      'no_ba_sampel_pupuk': noBaSampelPupuk,
      'supplier': supplier,
      'regional': regional,
      'wilayah': wilayah,
      'estate': estate,
      'pt': pt,
      'no_po': noPo,
      'no_bpb': noBpb,
      'qty_partai_pengiriman': qtyPartaiPengiriman,
      'qty_terima': qtyTerima,
      'jenis_kendaraan': jenisKendaraan,
      'tanggal_pengambilan_sampel': tanggalPengambilanSampel,
      'check_logo_perusahaan': checkLogoPerusahaan,
      'check_kondisi_karung': checkKondisiKarung,
      'check_jahitan_karung': checkJahitanKarung,
      'check_kontaminan': checkKontaminan,
      'check_jenis_kontaminan': checkJenisKontaminan,
      'check_persentase_kontaminan': checkPersentaseKontaminan,
      'check_bekas_gancu': checkBekasGancu,
      'diperiksa_estate_manager_nama': diperiksaEstateManagerNama,
      'diperiksa_ktu_nama': diperiksaKtuNama,
      'disaksikan_supplier_nama': disaksikanSupplierNama,
      'diambil_kepala_gudang': diambilKepalaGudang,
      'tanggal_terima_dari_gudang': tanggalTerimaDariGudang,
      'foto_terima_dari_gudang': fotoTerimaDariGudang,
      'tanggal_kirim_dari_estate': tanggalKirimDariEstate,
      'foto_kirim_dari_estate': fotoKirimDariEstate,
      'tanggal_terima_dari_estate': tanggalTerimaDariEstate,
      'foto_terima_dari_estate': fotoTerimaDariEstate,
      'nama_pengirim': namaPengirim,
      'no_surat': noSurat,
      'tanggal_kirim_lab': tanggalKirimLab,
      'foto_kirim_lab': fotoKirimLab,
      'tanggal_registrasi_lab': tanggalRegistrasiLab,
      'foto_registrasi_lab': fotoRegistrasiLab,
      'tanggal_estimasi_kupa': tanggalEstimasiKupa,
      'kode_tracking': kodeTracking,
      'no_sertifikat': noSertifikat,
      'tanggal_kirim_sertifikat_estate': tanggalKirimSertifikatEstate,
      'rekomendasi': rekomendasi,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
