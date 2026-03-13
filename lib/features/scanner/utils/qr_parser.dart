class QRParser {
  static QRData? parse(String qrCode) {
    try {
      final parts = qrCode.split(';');
      if (parts.length != 3) {
        return null;
      }

      final id = int.tryParse(parts[0].trim());
      final masterLsuId = int.tryParse(parts[1].trim());
      final kode = parts[2].trim();

      if (id == null || masterLsuId == null || kode.isEmpty) {
        return null;
      }

      return QRData(id: id, masterLsuId: masterLsuId, kode: kode);
    } catch (e) {
      return null;
    }
  }

  /// Sampel Pupuk QR format: id^supplier^kodeSampel^jenisPupukFull^qtyPartaiPengiriman
  static QRPupukData? parsePupuk(String raw) {
    try {
      final parts = raw.split('^');
      if (parts.length < 5) return null;
      final id = int.tryParse(parts[0].trim());
      if (id == null) return null;
      return QRPupukData(
        id: id,
        supplier: parts[1].trim(),
        kodeSampel: parts[2].trim(),
        jenisPupukFull: parts[3].trim(),
        qtyPartaiPengiriman: int.tryParse(parts[4].trim()),
      );
    } catch (e) {
      return null;
    }
  }
}

class QRData {
  final int id;
  final int masterLsuId;
  final String kode;

  QRData({required this.id, required this.masterLsuId, required this.kode});

  @override
  String toString() {
    return 'QRData(id: $id, masterLsuId: $masterLsuId, kode: $kode)';
  }
}

/// Sampel Pupuk QR format: id^supplier^kodeSampel^jenisPupukFull^qtyPartaiPengiriman
class QRPupukData {
  final int id;
  final String supplier;
  final String kodeSampel;
  final String jenisPupukFull;
  final int? qtyPartaiPengiriman;

  QRPupukData({
    required this.id,
    required this.supplier,
    required this.kodeSampel,
    required this.jenisPupukFull,
    this.qtyPartaiPengiriman,
  });

  @override
  String toString() {
    return 'QRPupukData(id: $id, supplier: $supplier, kodeSampel: $kodeSampel, jenisPupukFull: $jenisPupukFull, qtyPartaiPengiriman: $qtyPartaiPengiriman)';
  }
}
