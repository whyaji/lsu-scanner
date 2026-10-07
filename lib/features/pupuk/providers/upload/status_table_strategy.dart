import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/daos/status_table.dart';
import '../../../../core/network/api/upload_api.dart';
import '../../../../core/network/models/pupuk_upload_models.dart';
import 'pupuk_upload_strategy.dart';

/// Strategy for a type stored in a [StatusTable] whose server answer is a plain
/// success/failed id list and whose single local file is uploaded through
/// `/upload/photo-pupuk`.
abstract class StatusTableUploadStrategy<T> extends PupukUploadStrategy<T> {
  StatusTableUploadStrategy(this.table, this.uploadApi);

  final StatusTable<T> table;
  final UploadApi uploadApi;

  UploadTypeResult resultOf(SampelPupukUploadResponse response);

  int dataSampelPupukIdOf(T row);

  String kodeSampelOf(T row);

  @override
  Future<List<T>> loadPending() => table.getPending();

  @override
  String labelOf(T row) => kodeSampelOf(row);

  @override
  Future<String?> uploadFile(List<T> group, String path) async {
    final lead = group.first;
    final res = await uploadApi.uploadPhotoPupuk(
      filePath: path,
      dataSampelPupukId: dataSampelPupukIdOf(lead),
      kodeSampel: kodeSampelOf(lead),
      type: type,
    );
    if (res.success && res.data != null) return res.data!.filePath;
    return null;
  }

  @override
  Future<void> markPhotoFailure(T row) => table.updateStatus(
    idOf(row),
    AppConstants.statusError,
    errorMessage: photoFailureMessage,
  );

  @override
  Future<PupukUploadTypeResult> applyResult(
    SampelPupukUploadResponse response,
    String Function(int id) labelFor,
  ) async {
    final result = resultOf(response);
    for (final s in result.success) {
      await table.updateStatus(s.id, AppConstants.statusUploaded);
    }
    final failures = <PupukUploadFailure>[];
    for (final f in result.failed) {
      await table.updateStatus(
        f.id,
        AppConstants.statusError,
        errorMessage: f.error,
      );
      failures.add(
        PupukUploadFailure(
          id: f.id,
          label: labelFor(f.id),
          message: f.error,
          retryable: true,
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
