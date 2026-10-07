import '../../../core/network/api/upload_api.dart';
import '../../../core/network/models/pupuk_upload_models.dart';
import '../../pupuk/constants/pupuk_activity_types.dart';
import '../../pupuk/providers/upload/pupuk_upload_strategy.dart';
import '../data/pupuk_lab_dao.dart';
import '../models/pupuk_lab.dart';

/// Terima Lab receipts: each row uploads its own photos (1 to 5) one by one,
/// then travels as one `pupukLab[]` item keyed by its `clientUuid`.
class PupukLabUploadStrategy extends PupukUploadStrategy<PupukLab> {
  PupukLabUploadStrategy(this._dao, this._uploadApi);

  final PupukLabDao _dao;
  final UploadApi _uploadApi;

  @override
  String get type => kPupukLab;

  /// Rows SmartLab rejected for good stay out until the user edits them.
  @override
  Future<List<PupukLab>> loadPending() async =>
      (await _dao.getPending()).where((row) => !row.needsEdit).toList();

  @override
  int idOf(PupukLab row) => row.id!;

  @override
  String labelOf(PupukLab row) => row.noSurat;

  @override
  List<String> localFiles(List<PupukLab> group) =>
      group.first.fotoPaths.where((p) => p.trim().isNotEmpty).toList();

  @override
  Future<String?> uploadFile(List<PupukLab> group, String path) async {
    final res = await _uploadApi.uploadPhotoPupukLab(
      clientUuid: group.first.clientUuid,
      filePath: path,
    );
    if (res.success && res.data != null && res.data!.isNotEmpty) {
      return res.data;
    }
    return null;
  }

  @override
  Map<String, dynamic> buildItem(PupukLab row, List<String> serverFiles) =>
      row.toUploadItem(serverFiles).toJson();

  @override
  Future<void> markPhotoFailure(PupukLab row) =>
      _dao.markFailed(idOf(row), photoFailureMessage, retryable: true);

  /// Permanent failures are stored with `error_retryable = 0`, which
  /// [loadPending] skips; retryable ones go out again on the next upload.
  @override
  Future<PupukUploadTypeResult> applyResult(
    SampelPupukUploadResponse response,
    String Function(int id) labelFor,
  ) async {
    final result = response.pupukLab;
    for (final s in result.success) {
      await _dao.markUploaded(
        s.id,
        kodeTrack: s.kodeTrack,
        nomorLab: s.nomorLab,
        nomorKupa: s.nomorKupa,
      );
    }
    final failures = <PupukUploadFailure>[];
    for (final f in result.failed) {
      await _dao.markFailed(f.id, f.error, retryable: f.retryable);
      failures.add(
        PupukUploadFailure(
          id: f.id,
          label: labelFor(f.id),
          message: f.error,
          retryable: f.retryable,
        ),
      );
    }
    return PupukUploadTypeResult(
      type: type,
      uploaded: result.success.length,
      failures: failures,
    );
  }
}
