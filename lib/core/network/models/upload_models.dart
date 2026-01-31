class UploadItem {
  final int id;
  final int masterLsuId;
  final String kode;
  final String foto;
  final String tanggalTerima;
  final String waktuTerima;

  UploadItem({
    required this.id,
    required this.masterLsuId,
    required this.kode,
    required this.foto,
    required this.tanggalTerima,
    required this.waktuTerima,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masterLsuId': masterLsuId,
      'kode': kode,
      'foto': foto,
      'tanggalTerima': tanggalTerima,
      'waktuTerima': waktuTerima,
    };
  }
}

class CompleteUploadItem {
  final int id;
  final int masterLsuId;
  final String kode;
  final String foto;
  final String tanggalSelesai;
  final String waktuSelesai;

  CompleteUploadItem({
    required this.id,
    required this.masterLsuId,
    required this.kode,
    required this.foto,
    required this.tanggalSelesai,
    required this.waktuSelesai,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masterLsuId': masterLsuId,
      'kode': kode,
      'foto': foto,
      'tanggalSelesai': tanggalSelesai,
      'waktuSelesai': waktuSelesai,
    };
  }
}

class UploadSuccessItem {
  final int id;
  final String kode;

  UploadSuccessItem({required this.id, required this.kode});

  factory UploadSuccessItem.fromJson(Map<String, dynamic> json) {
    return UploadSuccessItem(
      id: json['id'] as int,
      kode: json['kode'] as String,
    );
  }
}

class UploadFailedItem {
  final int id;
  final String kode;
  final String error;

  UploadFailedItem({required this.id, required this.kode, required this.error});

  factory UploadFailedItem.fromJson(Map<String, dynamic> json) {
    return UploadFailedItem(
      id: json['id'] as int,
      kode: json['kode'] as String,
      error: json['error'] as String,
    );
  }
}

class UploadResponse {
  final List<UploadSuccessItem> success;
  final List<UploadFailedItem> failed;

  UploadResponse({required this.success, required this.failed});

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success:
          (json['success'] as List<dynamic>?)
              ?.map(
                (e) => UploadSuccessItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      failed:
          (json['failed'] as List<dynamic>?)
              ?.map((e) => UploadFailedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PhotoUploadResponse {
  final String filePath;

  PhotoUploadResponse({required this.filePath});

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResponse(filePath: json['filePath'] as String);
  }
}
