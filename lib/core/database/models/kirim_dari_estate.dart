class KirimDariEstate {
  final int? id;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String tanggalKirimDariEstate;
  final String? fotoKirimDariEstate;
  final String? namaPengirim;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String? updatedAt;

  KirimDariEstate({
    this.id,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    required this.tanggalKirimDariEstate,
    this.fotoKirimDariEstate,
    this.namaPengirim,
    this.status = 'not_uploaded',
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory KirimDariEstate.fromJson(Map<String, dynamic> json) {
    return KirimDariEstate(
      id: (json['id'] as num?)?.toInt(),
      dataSampelPupukId: json['data_sampel_pupuk_id'] as int,
      kodeSampel: json['kode_sampel'] as String,
      tanggalKirimDariEstate: json['tanggal_kirim_dari_estate'] as String,
      fotoKirimDariEstate: json['foto_kirim_dari_estate'] as String?,
      namaPengirim: json['nama_pengirim'] as String?,
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
      'tanggal_kirim_dari_estate': tanggalKirimDariEstate,
      'foto_kirim_dari_estate': fotoKirimDariEstate,
      'nama_pengirim': namaPengirim,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
