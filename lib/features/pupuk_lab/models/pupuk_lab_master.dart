List<String> _strings(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];

class PupukLabJenisSampel {
  const PupukLabJenisSampel({
    required this.id,
    this.kode,
    required this.nama,
    required this.progressIds,
    this.nomorDokumenKupa,
    this.nomorDokumenIdentitas,
    this.penyelia,
    this.petugasPreperasi,
  });

  final int id;
  final String? kode;
  final String nama;

  /// Allowed Status Pengerjaan ids for this jenis, in SmartLab order.
  final List<int> progressIds;
  final String? nomorDokumenKupa;
  final String? nomorDokumenIdentitas;
  final String? penyelia;
  final String? petugasPreperasi;

  factory PupukLabJenisSampel.fromJson(Map<String, dynamic> json) {
    final ids = json['progressIds'];
    return PupukLabJenisSampel(
      id: (json['id'] as num).toInt(),
      kode: json['kode'] as String?,
      nama: json['nama'] as String? ?? '',
      progressIds: ids is List
          ? ids.map((e) => (e as num).toInt()).toList()
          : const [],
      nomorDokumenKupa: json['nomorDokumenKupa'] as String?,
      nomorDokumenIdentitas: json['nomorDokumenIdentitas'] as String?,
      penyelia: json['penyelia'] as String?,
      petugasPreperasi: json['petugasPreperasi'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kode': kode,
    'nama': nama,
    'progressIds': progressIds,
    'nomorDokumenKupa': nomorDokumenKupa,
    'nomorDokumenIdentitas': nomorDokumenIdentitas,
    'penyelia': penyelia,
    'petugasPreperasi': petugasPreperasi,
  };
}

class PupukLabProgress {
  const PupukLabProgress({required this.id, required this.nama});

  final int id;
  final String nama;

  factory PupukLabProgress.fromJson(Map<String, dynamic> json) =>
      PupukLabProgress(
        id: (json['id'] as num).toInt(),
        nama: json['nama'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama};
}

class PupukLabParameterMaster {
  const PupukLabParameterMaster({
    required this.id,
    required this.jenisSampelId,
    required this.namaParameter,
    this.namaUnsur,
    required this.harga,
    this.satuan,
    this.metodeAnalisis,
  });

  final int id;
  final int jenisSampelId;
  final String namaParameter;
  final String? namaUnsur;
  final num harga;
  final String? satuan;
  final String? metodeAnalisis;

  factory PupukLabParameterMaster.fromJson(Map<String, dynamic> json) =>
      PupukLabParameterMaster(
        id: (json['id'] as num).toInt(),
        jenisSampelId: (json['jenisSampelId'] as num).toInt(),
        namaParameter: json['namaParameter'] as String? ?? '',
        namaUnsur: json['namaUnsur'] as String?,
        harga: json['harga'] as num? ?? 0,
        satuan: json['satuan'] as String?,
        metodeAnalisis: json['metodeAnalisis'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'jenisSampelId': jenisSampelId,
    'namaParameter': namaParameter,
    'namaUnsur': namaUnsur,
    'harga': harga,
    'satuan': satuan,
    'metodeAnalisis': metodeAnalisis,
  };
}

class PupukLabOptions {
  const PupukLabOptions({
    this.asalSampel = const [],
    this.kondisiSampel = const [],
    this.skalaPrioritas = const [],
    this.peralatan = const [],
  });

  final List<String> asalSampel;
  final List<String> kondisiSampel;
  final List<String> skalaPrioritas;
  final List<String> peralatan;

  factory PupukLabOptions.fromJson(Map<String, dynamic> json) =>
      PupukLabOptions(
        asalSampel: _strings(json['asalSampel']),
        kondisiSampel: _strings(json['kondisiSampel']),
        skalaPrioritas: _strings(json['skalaPrioritas']),
        peralatan: _strings(json['peralatan']),
      );

  Map<String, dynamic> toJson() => {
    'asalSampel': asalSampel,
    'kondisiSampel': kondisiSampel,
    'skalaPrioritas': skalaPrioritas,
    'peralatan': peralatan,
  };
}

class PupukLabDefaults {
  const PupukLabDefaults({this.emailCc = const [], this.asalSampel});

  final List<String> emailCc;
  final String? asalSampel;

  factory PupukLabDefaults.fromJson(Map<String, dynamic> json) =>
      PupukLabDefaults(
        emailCc: _strings(json['emailCc']),
        asalSampel: json['asalSampel'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'emailCc': emailCc,
    'asalSampel': asalSampel,
  };
}

/// SmartLab reference data for the Terima Lab form, as served by
/// `pupukLabMaster` in the sync response and cached in `pupuk_lab_master`.
/// [toJson] writes the same shape [fromApiJson] reads.
class PupukLabMaster {
  const PupukLabMaster({
    required this.version,
    required this.fetchedAt,
    required this.jenisSampel,
    required this.progressPengerjaan,
    required this.parameterAnalisis,
    required this.departemen,
    required this.options,
    required this.defaults,
  });

  final String version;

  /// ISO 8601 time the backend fetched the snapshot from SmartLab.
  final String fetchedAt;
  final List<PupukLabJenisSampel> jenisSampel;
  final List<PupukLabProgress> progressPengerjaan;
  final List<PupukLabParameterMaster> parameterAnalisis;
  final List<String> departemen;
  final PupukLabOptions options;
  final PupukLabDefaults defaults;

  factory PupukLabMaster.fromApiJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic> json) parse) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return raw.map((e) => parse(e as Map<String, dynamic>)).toList();
    }

    return PupukLabMaster(
      version: json['version'] as String? ?? '',
      fetchedAt: json['fetchedAt'] as String? ?? '',
      jenisSampel: list('jenisSampel', PupukLabJenisSampel.fromJson),
      progressPengerjaan: list('progressPengerjaan', PupukLabProgress.fromJson),
      parameterAnalisis: list(
        'parameterAnalisis',
        PupukLabParameterMaster.fromJson,
      ),
      departemen: _strings(json['departemen']),
      options: PupukLabOptions.fromJson(
        json['options'] as Map<String, dynamic>? ?? const {},
      ),
      defaults: PupukLabDefaults.fromJson(
        json['defaults'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'fetchedAt': fetchedAt,
    'jenisSampel': jenisSampel.map((e) => e.toJson()).toList(),
    'progressPengerjaan': progressPengerjaan.map((e) => e.toJson()).toList(),
    'parameterAnalisis': parameterAnalisis.map((e) => e.toJson()).toList(),
    'departemen': departemen,
    'options': options.toJson(),
    'defaults': defaults.toJson(),
  };

  /// A form can only be filled when it has something to choose from.
  bool get isUsable => jenisSampel.isNotEmpty;

  DateTime? get fetchedAtTime => DateTime.tryParse(fetchedAt);

  PupukLabJenisSampel? jenisById(int id) {
    for (final jenis in jenisSampel) {
      if (jenis.id == id) return jenis;
    }
    return null;
  }

  /// Status Pengerjaan choices for [jenisId]: the jenis `progressIds` in their
  /// own order, named through [progressPengerjaan]. Unknown ids are skipped.
  List<PupukLabProgress> progressOptionsFor(int jenisId) {
    final jenis = jenisById(jenisId);
    if (jenis == null) return const [];
    final byId = {for (final p in progressPengerjaan) p.id: p};
    return [
      for (final id in jenis.progressIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<PupukLabParameterMaster> parametersFor(int jenisId) => [
    for (final p in parameterAnalisis)
      if (p.jenisSampelId == jenisId) p,
  ];

  PupukLabParameterMaster? parameterById(int id) {
    for (final p in parameterAnalisis) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// True when the snapshot was fetched from SmartLab more than [maxAge] ago.
  bool isOlderThan(Duration maxAge, {DateTime? now}) {
    final fetched = fetchedAtTime;
    if (fetched == null) return true;
    return (now ?? DateTime.now()).difference(fetched) > maxAge;
  }
}
