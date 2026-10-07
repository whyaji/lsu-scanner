import '../../../../core/network/api/upload_api.dart';
import '../../../../core/network/models/pupuk_upload_models.dart';
import '../../../../core/utils/image_utils.dart';
import 'pupuk_upload_strategy.dart';

/// Result of one [PupukUploadPipeline.run].
class PupukUploadOutcome {
  const PupukUploadOutcome({
    required this.total,
    required this.byType,
    this.error,
  });

  /// Pending rows found across all types before the run.
  final int total;

  /// Only types that had pending rows appear here.
  final Map<String, PupukUploadTypeResult> byType;

  /// Set when the upload request itself failed; every row then counts failed.
  final String? error;

  int get uploaded => byType.values.fold(0, (sum, r) => sum + r.uploaded);
  int get failed => byType.values.fold(0, (sum, r) => sum + r.failed);
}

/// Loads pending rows of every strategy, uploads their photos, sends one
/// `POST /data-sampel-pupuk/upload` and writes the verdicts back.
class PupukUploadPipeline {
  PupukUploadPipeline({
    required this.strategies,
    required this.uploadApi,
    Future<String?> Function(String path)? compress,
    this.retryDelay = const Duration(milliseconds: 400),
  }) : _compress = compress ?? ImageUtils.compressImage;

  final List<PupukUploadStrategy<dynamic>> strategies;
  final UploadApi uploadApi;
  final Duration retryDelay;
  final Future<String?> Function(String path) _compress;

  Future<PupukUploadOutcome> run({
    void Function(UploadSampelPupukProgress progress)? onProgress,
  }) async {
    final batches = [
      for (final strategy in strategies) await strategy.load(),
    ];
    final total = batches.fold(0, (sum, b) => sum + b.rowCount);
    if (total == 0) return const PupukUploadOutcome(total: 0, byType: {});

    final context = PupukUploadContext(
      total: total,
      compress: _compress,
      retryDelay: retryDelay,
      onProgress: onProgress ?? (_) {},
    );
    final prepared = <PreparedPupukUpload>[];
    for (final batch in batches) {
      if (batch.rowCount == 0) continue;
      prepared.add(await batch.prepare(context));
    }

    final hasItems = prepared.any((p) => p.items.isNotEmpty);
    if (!hasItems) {
      return PupukUploadOutcome(
        total: total,
        byType: {
          for (final p in prepared)
            p.type: PupukUploadTypeResult(
              type: p.type,
              failures: p.photoFailures,
            ),
        },
      );
    }

    final response = await uploadApi.uploadSampelPupuk(
      SampelPupukUploadPayload({for (final p in prepared) p.type: p.items}),
    );
    if (!response.success || response.data == null) {
      final message = response.error?.message ?? 'Upload gagal';
      return PupukUploadOutcome(
        total: total,
        error: message,
        byType: {
          for (final p in prepared)
            p.type: PupukUploadTypeResult(
              type: p.type,
              failures: [
                ...p.photoFailures,
                for (final entry in p.sentLabels.entries)
                  PupukUploadFailure(
                    id: entry.key,
                    label: entry.value,
                    message: message,
                    retryable: true,
                  ),
              ],
            ),
        },
      );
    }

    final byType = <String, PupukUploadTypeResult>{};
    for (final p in prepared) {
      final applied = await p.apply(response.data!);
      byType[p.type] = applied.withExtraFailures(p.photoFailures);
    }
    return PupukUploadOutcome(total: total, byType: byType);
  }
}
