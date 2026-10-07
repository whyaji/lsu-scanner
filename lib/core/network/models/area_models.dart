class EstateItem {
  final int id;
  final int regional;
  final int wilayah;
  final String abbr;
  final String nama;

  EstateItem({
    required this.id,
    required this.regional,
    required this.wilayah,
    required this.abbr,
    required this.nama,
  });

  factory EstateItem.fromJson(Map<String, dynamic> json) {
    return EstateItem(
      id: json['id'] as int,
      regional: (json['regional'] as num).toInt(),
      wilayah: (json['wilayah'] as num).toInt(),
      abbr: json['abbr'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
    );
  }
}

class AreaEstateResponse {
  final List<EstateItem> data;
  final int total;

  AreaEstateResponse({required this.data, required this.total});

  factory AreaEstateResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'];
    if (list is List) {
      return AreaEstateResponse(
        data: list
            .map((e) => EstateItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? list.length,
      );
    }
    return AreaEstateResponse(data: [], total: 0);
  }
}
