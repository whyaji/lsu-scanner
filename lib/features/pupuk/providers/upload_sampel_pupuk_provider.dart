import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/network/api_providers.dart';
import '../../pupuk_lab/providers/pupuk_lab_providers.dart';
import '../../pupuk_lab/providers/pupuk_lab_upload_strategy.dart';
import 'upload/pupuk_upload_pipeline.dart';
import 'upload/pupuk_upload_strategies.dart';
import 'upload/pupuk_upload_strategy.dart';

export 'upload/pupuk_upload_strategy.dart'
    show UploadSampelPupukProgress, PupukUploadFailure, PupukUploadTypeResult;

class UploadSampelPupukState {
  final bool isUploading;
  final UploadSampelPupukProgress? progress;
  final String? error;

  /// After the run: counts for the result modal (like the LSU upload screen).
  final int? lastSuccessCount;
  final int? lastFailedCount;

  /// After the run: outcome per activity type key (`kKirimLab`, `kPupukLab`,
  /// ...), only for types that had pending rows. Each failure says whether the
  /// user has to fix the row (`retryable` false) or can simply upload again.
  final Map<String, PupukUploadTypeResult> resultsByType;

  UploadSampelPupukState({
    this.isUploading = false,
    this.progress,
    this.error,
    this.lastSuccessCount,
    this.lastFailedCount,
    this.resultsByType = const {},
  });
}

class UploadSampelPupukNotifier extends StateNotifier<UploadSampelPupukState> {
  UploadSampelPupukNotifier(this._pipeline) : super(UploadSampelPupukState());

  final PupukUploadPipeline _pipeline;

  Future<void> uploadAll() async {
    state = UploadSampelPupukState(isUploading: true);

    try {
      final outcome = await _pipeline.run(
        onProgress: (progress) => state = UploadSampelPupukState(
          isUploading: true,
          progress: progress,
        ),
      );
      if (outcome.total == 0) {
        state = UploadSampelPupukState();
        return;
      }
      state = UploadSampelPupukState(
        error: outcome.error,
        lastSuccessCount: outcome.uploaded,
        lastFailedCount: outcome.error != null ? outcome.total : outcome.failed,
        resultsByType: outcome.byType,
      );
    } catch (e) {
      state = UploadSampelPupukState(error: e.toString());
    }
  }
}

final pupukUploadPipelineProvider = Provider<PupukUploadPipeline>((ref) {
  final uploadApi = ref.watch(uploadApiProvider);
  return PupukUploadPipeline(
    uploadApi: uploadApi,
    strategies: [
      KirimDariEstateUploadStrategy(
        ref.watch(kirimDariEstateDaoProvider),
        uploadApi,
      ),
      KirimLabUploadStrategy(ref.watch(kirimLabDaoProvider), uploadApi),
      KirimSertifikatEstateUploadStrategy(
        ref.watch(kirimSertifikatEstateDaoProvider),
        uploadApi,
      ),
      PupukLabUploadStrategy(ref.watch(pupukLabDaoProvider), uploadApi),
    ],
  );
});

final uploadSampelPupukProvider =
    StateNotifierProvider<UploadSampelPupukNotifier, UploadSampelPupukState>(
      (ref) => UploadSampelPupukNotifier(ref.watch(pupukUploadPipelineProvider)),
    );
