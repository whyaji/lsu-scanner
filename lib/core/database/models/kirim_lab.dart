class KirimLab {
  final int? id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String tanggalKirimLab;
  final String? fotoKirimLab;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String? updatedAt;

  KirimLab({
    this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    required this.tanggalKirimLab,
    this.fotoKirimLab,
    this.status = 'not_uploaded',
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory KirimLab.fromJson(Map<String, dynamic> json) {
    return KirimLab(
      id: (json['id'] as num?)?.toInt(),
      dataSampelPupukId: json['data_sampel_pupuk_id'] as int,
      kodeSampel: json['kode_sampel'] as String,
      tanggalKirimLab: json['tanggal_kirim_lab'] as String,
      fotoKirimLab: json['foto_kirim_lab'] as String?,
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
      'tanggal_kirim_lab': tanggalKirimLab,
      'foto_kirim_lab': fotoKirimLab,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
