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
