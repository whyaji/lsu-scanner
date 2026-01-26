import '../models/master_lsu.dart';

class ReceivedSample {
  final int? id;
  final int dataLsuId;
  final int masterLsuId;
  final String kode;
  final String tanggalTerima;
  final String waktuTerima;
  final String fotoPath;
  final String status;
  final String? errorMessage;
  final int? userId;
  final String createdAt;
  final String? updatedAt;

  // Related data (not stored in DB)
  MasterLsu? masterLsu;

  ReceivedSample({
    this.id,
    required this.dataLsuId,
    required this.masterLsuId,
    required this.kode,
    required this.tanggalTerima,
    required this.waktuTerima,
    required this.fotoPath,
    this.status = 'not_uploaded',
    this.errorMessage,
    this.userId,
    required this.createdAt,
    this.updatedAt,
    this.masterLsu,
  });

  factory ReceivedSample.fromJson(Map<String, dynamic> json) {
    return ReceivedSample(
      id: json['id'] as int?,
      dataLsuId: json['data_lsu_id'] as int,
      masterLsuId: json['master_lsu_id'] as int,
      kode: json['kode'] as String,
      tanggalTerima: json['tanggal_terima'] as String,
      waktuTerima: json['waktu_terima'] as String,
      fotoPath: json['foto_path'] as String,
      status: json['status'] as String? ?? 'not_uploaded',
      errorMessage: json['error_message'] as String?,
      userId: json['user_id'] as int?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'data_lsu_id': dataLsuId,
      'master_lsu_id': masterLsuId,
      'kode': kode,
      'tanggal_terima': tanggalTerima,
      'waktu_terima': waktuTerima,
      'foto_path': fotoPath,
      'status': status,
      'error_message': errorMessage,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ReceivedSample copyWith({
    int? id,
    int? dataLsuId,
    int? masterLsuId,
    String? kode,
    String? tanggalTerima,
    String? waktuTerima,
    String? fotoPath,
    String? status,
    String? errorMessage,
    int? userId,
    String? createdAt,
    String? updatedAt,
    MasterLsu? masterLsu,
  }) {
    return ReceivedSample(
      id: id ?? this.id,
      dataLsuId: dataLsuId ?? this.dataLsuId,
      masterLsuId: masterLsuId ?? this.masterLsuId,
      kode: kode ?? this.kode,
      tanggalTerima: tanggalTerima ?? this.tanggalTerima,
      waktuTerima: waktuTerima ?? this.waktuTerima,
      fotoPath: fotoPath ?? this.fotoPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      masterLsu: masterLsu ?? this.masterLsu,
    );
  }
}
