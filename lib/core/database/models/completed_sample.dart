import 'master_lsu.dart';

class CompletedSample {
  final int? id;
  final int dataLsuId;
  final int masterLsuId;
  final String kode;
  final String tanggalSelesai;
  final String waktuSelesai;
  final String fotoPath;
  final String status;
  final String? errorMessage;
  final int? userId;
  final String createdAt;
  final String? updatedAt;

  // Related data (not stored in DB)
  MasterLsu? masterLsu;

  CompletedSample({
    this.id,
    required this.dataLsuId,
    required this.masterLsuId,
    required this.kode,
    required this.tanggalSelesai,
    required this.waktuSelesai,
    required this.fotoPath,
    this.status = 'not_uploaded',
    this.errorMessage,
    this.userId,
    required this.createdAt,
    this.updatedAt,
    this.masterLsu,
  });

  factory CompletedSample.fromJson(Map<String, dynamic> json) {
    return CompletedSample(
      id: json['id'] as int?,
      dataLsuId: json['data_lsu_id'] as int,
      masterLsuId: json['master_lsu_id'] as int,
      kode: json['kode'] as String,
      tanggalSelesai: json['tanggal_selesai'] as String,
      waktuSelesai: json['waktu_selesai'] as String,
      fotoPath: json['foto_path'] as String,
      status: json['status'] as String? ?? 'not_uploaded',
      errorMessage: json['error_message'] as String?,
      userId: json['user_id'] as int?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
      masterLsu: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'data_lsu_id': dataLsuId,
      'master_lsu_id': masterLsuId,
      'kode': kode,
      'tanggal_selesai': tanggalSelesai,
      'waktu_selesai': waktuSelesai,
      'foto_path': fotoPath,
      'status': status,
      'error_message': errorMessage,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
