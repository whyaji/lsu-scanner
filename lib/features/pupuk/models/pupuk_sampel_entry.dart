import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../scanner/utils/qr_parser.dart';

/// One sampel pupuk selected for an activity (e.g. Kirim Lab batch).
class PupukSampelEntry {
  final int dataSampelPupukId;
  final String kodeSampel;
  final DataSampelPupuk? dataSampelPupuk;
  final QRPupukData qrPupukData;
  final bool fromSync;

  const PupukSampelEntry({
    required this.dataSampelPupukId,
    required this.kodeSampel,
    this.dataSampelPupuk,
    required this.qrPupukData,
    required this.fromSync,
  });

  factory PupukSampelEntry.fromScan({
    required QRPupukData qrPupukData,
    DataSampelPupuk? dataSampelPupuk,
  }) {
    final kode = qrPupukData.kodeSampel;
    return PupukSampelEntry(
      dataSampelPupukId: dataSampelPupuk?.id ?? qrPupukData.id,
      kodeSampel: kode.isEmpty ? qrPupukData.kodeSampel : kode,
      dataSampelPupuk: dataSampelPupuk,
      qrPupukData: qrPupukData,
      fromSync: dataSampelPupuk != null,
    );
  }

  String get displayKodeSampel =>
      kodeSampel.isEmpty ? qrPupukData.kodeSampel : kodeSampel;
}
