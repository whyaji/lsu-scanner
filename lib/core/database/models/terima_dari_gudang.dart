class TerimaDariGudang {
  final int? id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String tanggalTerimaDariGudang;
  final String? fotoTerimaDariGudang;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String? updatedAt;

  TerimaDariGudang({
    this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    required this.tanggalTerimaDariGudang,
    this.fotoTerimaDariGudang,
    this.status = 'not_uploaded',
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory TerimaDariGudang.fromJson(Map<String, dynamic> json) {
    return TerimaDariGudang(
      id: (json['id'] as num?)?.toInt(),
      dataSampelPupukId: json['data_sampel_pupuk_id'] as int,
      kodeSampel: json['kode_sampel'] as String,
      tanggalTerimaDariGudang: json['tanggal_terima_dari_gudang'] as String,
      fotoTerimaDariGudang: json['foto_terima_dari_gudang'] as String?,
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
      'tanggal_terima_dari_gudang': tanggalTerimaDariGudang,
      'foto_terima_dari_gudang': fotoTerimaDariGudang,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
