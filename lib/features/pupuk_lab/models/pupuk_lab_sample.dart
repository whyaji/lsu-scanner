/// One sample inside a Terima Lab receipt: a SampleTrack record scanned from
/// its QR label, or a manual code that only exists in SmartLab.
class PupukLabSample {
  const PupukLabSample({
    required this.kodeSampel,
    this.dataSampelPupukId,
    this.isManual = false,
  }) : assert(
         isManual || dataSampelPupukId != null,
         'A scanned sample needs its dataSampelPupukId',
       );

  final int? dataSampelPupukId;
  final String kodeSampel;
  final bool isManual;

  factory PupukLabSample.fromJson(Map<String, dynamic> json) {
    return PupukLabSample(
      dataSampelPupukId: (json['dataSampelPupukId'] as num?)?.toInt(),
      kodeSampel: json['kodeSampel'] as String,
      isManual: json['isManual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'dataSampelPupukId': dataSampelPupukId,
    'kodeSampel': kodeSampel,
    'isManual': isManual,
  };

  @override
  bool operator ==(Object other) =>
      other is PupukLabSample &&
      other.dataSampelPupukId == dataSampelPupukId &&
      other.kodeSampel == kodeSampel &&
      other.isManual == isManual;

  @override
  int get hashCode => Object.hash(dataSampelPupukId, kodeSampel, isManual);
}
