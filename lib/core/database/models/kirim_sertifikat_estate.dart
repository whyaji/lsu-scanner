class KirimSertifikatEstate {
  final int? id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String tanggalKirimSertifikatEstate;
  final String rekomendasi;
  final String fileSertifikat;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String? updatedAt;

  KirimSertifikatEstate({
    this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    required this.tanggalKirimSertifikatEstate,
    required this.rekomendasi,
    required this.fileSertifikat,
    this.status = 'not_uploaded',
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory KirimSertifikatEstate.fromJson(Map<String, dynamic> json) {
    return KirimSertifikatEstate(
      id: (json['id'] as num?)?.toInt(),
      dataSampelPupukId: json['data_sampel_pupuk_id'] as int,
      kodeSampel: json['kode_sampel'] as String,
      tanggalKirimSertifikatEstate:
          json['tanggal_kirim_sertifikat_estate'] as String,
      rekomendasi: (json['rekomendasi'] as String?) ?? '',
      fileSertifikat: (json['file_sertifikat'] as String?) ?? '',
      status: json['status'] as String? ?? 'not_uploaded',
      errorMessage: json['error_message'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'data_sampel_pupuk_id': dataSampelPupukId,
      'kode_sampel': kodeSampel,
      'tanggal_kirim_sertifikat_estate': tanggalKirimSertifikatEstate,
      'rekomendasi': rekomendasi,
      'file_sertifikat': fileSertifikat,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
