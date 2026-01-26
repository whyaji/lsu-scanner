class MasterSampel {
  final int id;
  final String nama;
  final String? createdAt;
  final String? updatedAt;

  MasterSampel({
    required this.id,
    required this.nama,
    this.createdAt,
    this.updatedAt,
  });

  factory MasterSampel.fromJson(Map<String, dynamic> json) {
    return MasterSampel(
      id: json['id'] as int,
      nama: json['nama'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
