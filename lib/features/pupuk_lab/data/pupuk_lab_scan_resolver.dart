import '../../../core/database/daos/data_sampel_pupuk_dao.dart';
import '../../pupuk/constants/pupuk_activity_types.dart';
import '../../scanner/utils/qr_parser.dart';
import '../models/pupuk_lab_draft.dart';
import '../models/pupuk_lab_sample.dart';

/// Why a scanned label was not added to the receipt.
enum PupukLabScanProblem {
  invalidQr,

  /// Already in this receipt. Not an error worth a dialog.
  duplicate,

  /// The record is not on this device: sync, then scan again.
  notFound,
  notSentToLab,
  alreadyReceived,
  reservedLocally,

  /// The sample belongs to another no. surat than the receipt.
  noSuratMismatch,
}

sealed class PupukLabScanResult {
  const PupukLabScanResult();
}

class PupukLabScanAccepted extends PupukLabScanResult {
  const PupukLabScanAccepted(this.sample, {this.noSurat});

  final PupukLabDraftSample sample;

  /// No. surat of the sample, null when the record has none.
  final String? noSurat;
}

class PupukLabScanRejected extends PupukLabScanResult {
  const PupukLabScanRejected(this.problem, this.title, this.message);

  final PupukLabScanProblem problem;
  final String title;
  final String message;
}

/// Turns a scanned QR string into "add this sample" or "here is why not".
class PupukLabScanResolver {
  PupukLabScanResolver(this._dao);

  final DataSampelPupukDao _dao;

  /// [existingKodes] are the codes already on the receipt, [noSurat] is its
  /// current no. surat (empty until the first sample or the user sets one), and
  /// [reservedKodes] are codes held by other local receipts.
  Future<PupukLabScanResult> resolve(
    String raw, {
    required Set<String> existingKodes,
    required String noSurat,
    required Set<String> reservedKodes,
  }) async {
    final qr = QRParser.parsePupuk(raw);
    if (qr == null || qr.kodeSampel.isEmpty) {
      return const PupukLabScanRejected(
        PupukLabScanProblem.invalidQr,
        'QR tidak dikenali',
        'Label ini bukan label sampel pupuk SampleTrack. Pindai QR di label sampel.',
      );
    }
    final kode = qr.kodeSampel;
    if (existingKodes.contains(kode)) {
      return PupukLabScanRejected(
        PupukLabScanProblem.duplicate,
        'Sampel sudah ada',
        '$kode sudah ada di daftar penerimaan ini.',
      );
    }

    final data = await _dao.getById(qr.id);
    final eligibility = pupukLabEligibility(
      data,
      individualKodeSampel: kode,
      pendingPupukLabKodes: reservedKodes,
    );
    switch (eligibility) {
      case PupukLabEligibility.notFound:
        return PupukLabScanRejected(
          PupukLabScanProblem.notFound,
          'Sampel belum ada di perangkat',
          '$kode belum ada di data yang tersimpan. Sinkronkan data, lalu pindai lagi.',
        );
      case PupukLabEligibility.notSentToLab:
        return PupukLabScanRejected(
          PupukLabScanProblem.notSentToLab,
          'Sampel belum dikirim ke lab',
          '$kode belum tercatat Kirim Lab. Minta NT mencatat Kirim Lab dulu, lalu sinkronkan.',
        );
      case PupukLabEligibility.alreadyReceived:
        return PupukLabScanRejected(
          PupukLabScanProblem.alreadyReceived,
          'Sampel sudah diterima lab',
          '$kode sudah tercatat diterima di lab.',
        );
      case PupukLabEligibility.reservedLocally:
        return PupukLabScanRejected(
          PupukLabScanProblem.reservedLocally,
          'Sampel sudah ada di penerimaan lain',
          '$kode sudah masuk penerimaan lain di perangkat ini. Hapus penerimaan itu bila salah.',
        );
      case PupukLabEligibility.eligible:
        break;
    }

    final sampleNoSurat = pupukSampleNoSurat(data, kode);
    final current = noSurat.trim();
    if (current.isNotEmpty &&
        sampleNoSurat != null &&
        sampleNoSurat != current) {
      return PupukLabScanRejected(
        PupukLabScanProblem.noSuratMismatch,
        'No. surat berbeda',
        '$kode memakai no. surat $sampleNoSurat, sedangkan penerimaan ini '
            'memakai $current. Satu penerimaan hanya boleh satu no. surat. '
            'Simpan penerimaan ini dulu, lalu buat penerimaan baru untuk sampel tersebut.',
      );
    }

    final record = data!;
    return PupukLabScanAccepted(
      PupukLabDraftSample(
        sample: PupukLabSample(dataSampelPupukId: record.id, kodeSampel: kode),
        supplier: _nonBlank(record.supplier) ?? _nonBlank(qr.supplier),
        jenisPupuk:
            _nonBlank(record.jenisPupuk) ??
            _nonBlank(record.jenisPupukFull) ??
            _nonBlank(qr.jenisPupukFull),
        estate: _nonBlank(record.estate),
        qtyKg: record.qtyTerima ?? qr.qtyTerima,
      ),
      noSurat: sampleNoSurat,
    );
  }

  /// Whether [kode] is a code of a record already on this device. A manual
  /// code must not collide with one: SmartLab would end up with two rows for
  /// the same sample. Parent codes with `ABCD` stand for four individual codes.
  Future<bool> isSystemKode(String kode) async {
    final target = kode.trim();
    for (final record in await _dao.getAll()) {
      final parent = record.kodeSampel;
      if (parent == null) continue;
      if (parent == target) return true;
      if (parent.contains('ABCD')) {
        for (final letter in const ['A', 'B', 'C', 'D']) {
          if (parent.replaceFirst('ABCD', letter) == target) return true;
        }
      }
    }
    return false;
  }

  /// Display data for samples of a saved receipt that is being edited.
  Future<List<PupukLabDraftSample>> describeSamples(
    List<PupukLabSample> samples,
  ) async {
    final result = <PupukLabDraftSample>[];
    for (final sample in samples) {
      final id = sample.dataSampelPupukId;
      final record = (sample.isManual || id == null)
          ? null
          : await _dao.getById(id);
      result.add(
        PupukLabDraftSample(
          sample: sample,
          supplier: _nonBlank(record?.supplier),
          jenisPupuk:
              _nonBlank(record?.jenisPupuk) ??
              _nonBlank(record?.jenisPupukFull),
          estate: _nonBlank(record?.estate),
          qtyKg: record?.qtyTerima,
        ),
      );
    }
    return result;
  }

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
