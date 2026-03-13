class TerimaDariEstate {
  final int? id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String? noSurat;
  final String tanggalTerimaDariEstate;
  final String? fotoTerimaDariEstate;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String? updatedAt;

  TerimaDariEstate({
    this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    this.noSurat,
    required this.tanggalTerimaDariEstate,
    this.fotoTerimaDariEstate,
    this.status = 'not_uploaded',
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory TerimaDariEstate.fromJson(Map<String, dynamic> json) {
    return TerimaDariEstate(
      id: (json['id'] as num?)?.toInt(),
      dataSampelPupukId: json['data_sampel_pupuk_id'] as int,
      kodeSampel: json['kode_sampel'] as String,
      noSurat: json['no_surat'] as String?,
      tanggalTerimaDariEstate: json['tanggal_terima_dari_estate'] as String,
      fotoTerimaDariEstate: json['foto_terima_dari_estate'] as String?,
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
      'no_surat': noSurat,
      'tanggal_terima_dari_estate': tanggalTerimaDariEstate,
      'foto_terima_dari_estate': fotoTerimaDariEstate,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
