/// Activity type keys for Sampel Pupuk (must match API: terimaDariGudang, etc.)
const String kTerimaDariGudang = 'terimaDariGudang';
const String kKirimDariEstate = 'kirimDariEstate';
const String kTerimaDariEstate = 'terimaDariEstate';
const String kKirimLab = 'kirimLab';

const List<String> kAllPupukActivityTypes = [
  kTerimaDariGudang,
  kKirimDariEstate,
  kTerimaDariEstate,
  kKirimLab,
];

String labelForPupukActivityType(String type) {
  switch (type) {
    case kTerimaDariGudang:
      return 'Terima dari Gudang';
    case kKirimDariEstate:
      return 'Kirim dari Estate';
    case kTerimaDariEstate:
      return 'Terima dari Estate';
    case kKirimLab:
      return 'Kirim Lab';
    default:
      return type;
  }
}

/// Returns activity types allowed for user with given access list.
List<String> allowedPupukActivityTypes(List<String>? access) {
  if (access == null || access.isEmpty) return [];
  final list = <String>[];
  if (access.contains('pupuk:estate')) {
    list.add(kTerimaDariGudang);
    list.add(kKirimDariEstate);
  }
  if (access.contains('pupuk:nt')) {
    list.add(kTerimaDariEstate);
    list.add(kKirimLab);
  }
  return list;
}
