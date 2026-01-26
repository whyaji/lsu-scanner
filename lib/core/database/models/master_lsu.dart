class MasterLsu {
  final int id;
  final int regional;
  final String? pt;
  final String? statusKebun;
  final String? estate;
  final int? wilayah;
  final String? afdeling;
  final String? blok;
  final String? groupBlok;
  final int? tahunTanam;
  final String? varietas;
  final String? jenisTanah;
  final String? topografi;
  final String? luasHa;
  final int? jmlPokok;
  final int? jmlPokokProduktif;
  final int? sph;
  final String? createdAt;
  final String? updatedAt;

  MasterLsu({
    required this.id,
    required this.regional,
    this.pt,
    this.statusKebun,
    this.estate,
    this.wilayah,
    this.afdeling,
    this.blok,
    this.groupBlok,
    this.tahunTanam,
    this.varietas,
    this.jenisTanah,
    this.topografi,
    this.luasHa,
    this.jmlPokok,
    this.jmlPokokProduktif,
    this.sph,
    this.createdAt,
    this.updatedAt,
  });

  factory MasterLsu.fromJson(Map<String, dynamic> json) {
    return MasterLsu(
      id: json['id'] as int,
      regional: json['regional'] as int,
      pt: json['pt'] as String?,
      statusKebun: json['statusKebun'] as String? ?? json['status_kebun'] as String?,
      estate: json['estate'] as String?,
      wilayah: json['wilayah'] as int?,
      afdeling: json['afdeling'] as String?,
      blok: json['blok'] as String?,
      groupBlok: json['groupBlok'] as String? ?? json['group_blok'] as String?,
      tahunTanam: json['tahunTanam'] as int? ?? json['tahun_tanam'] as int?,
      varietas: json['varietas'] as String?,
      jenisTanah: json['jenisTanah'] as String? ?? json['jenis_tanah'] as String?,
      topografi: json['topografi'] as String?,
      luasHa: json['luasHa'] as String? ?? json['luas_ha'] as String?,
      jmlPokok: json['jmlPokok'] as int? ?? json['jml_pokok'] as int?,
      jmlPokokProduktif: json['jmlPokokProduktif'] as int? ?? json['jml_pokok_produktif'] as int?,
      sph: json['sph'] == null
          ? null
          : (json['sph'] is int
              ? json['sph'] as int
              : int.tryParse(json['sph'].toString())),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regional': regional,
      'pt': pt,
      'status_kebun': statusKebun,
      'estate': estate,
      'wilayah': wilayah,
      'afdeling': afdeling,
      'blok': blok,
      'group_blok': groupBlok,
      'tahun_tanam': tahunTanam,
      'varietas': varietas,
      'jenis_tanah': jenisTanah,
      'topografi': topografi,
      'luas_ha': luasHa,
      'jml_pokok': jmlPokok,
      'jml_pokok_produktif': jmlPokokProduktif,
      'sph': sph,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
