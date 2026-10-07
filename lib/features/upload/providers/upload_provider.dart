import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/daos/lsu_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/network/api/upload_api.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/database/models/completed_sample.dart';
import '../../../core/network/models/upload_models.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/constants/app_constants.dart';

class UploadProgress {
  final int total;
  final int current;
  final int percentage;
  final String currentItem;

  UploadProgress({
    required this.total,
    required this.current,
    required this.percentage,
    required this.currentItem,
  });
}

class UploadResult {
  final ReceivedSample sample;
  final bool success;
  final String? error;

  UploadResult({required this.sample, required this.success, this.error});
}

class UploadState {
  final bool isUploading;
  final UploadProgress? progress;
  final List<UploadResult> results;
  final String? error;

  UploadState({
    this.isUploading = false,
    this.progress,
    this.results = const [],
    this.error,
  });

  UploadState copyWith({
    bool? isUploading,
    UploadProgress? progress,
    List<UploadResult>? results,
    String? error,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      results: results ?? this.results,
      error: error,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  final UploadApi _api;
  final LsuDao _lsuDao;

  UploadNotifier(this._api, this._lsuDao) : super(UploadState());

  Future<void> uploadAll() async {
    state = state.copyWith(isUploading: true, error: null, results: []);

    try {
      // Get pending samples
      final samples = await _lsuDao.received.getPending();
      if (samples.isEmpty) {
        state = state.copyWith(isUploading: false);
        return;
      }

      // Step 1: Batch upload data
      final uploadItems = samples.map((s) {
        final fileName = ImageUtils.getFileName(s.fotoPath);
        return UploadItem(
          id: s.dataLsuId,
          masterLsuId: s.masterLsuId,
          kode: s.kode,
          foto: fileName,
          tanggalTerima: s.tanggalTerima,
          waktuTerima: s.waktuTerima,
        );
      }).toList();

      final batchResponse = await _api.batchUpload(uploadItems);

      if (!batchResponse.success || batchResponse.data == null) {
        state = state.copyWith(
          isUploading: false,
          error: batchResponse.error?.message ?? 'Upload failed',
        );
        return;
      }

      final uploadData = batchResponse.data!;

      // Step 2: Upload photos for success items + failed items with "Status already received"
      const statusAlreadyReceivedError =
          'Status already received, need reupload photo';
      final statusAlreadyReceivedItems = uploadData.failed
          .where(
            (item) =>
                item.error.toLowerCase() ==
                statusAlreadyReceivedError.toLowerCase(),
          )
          .toList();
      final otherFailedItems = uploadData.failed
          .where(
            (item) =>
                item.error.toLowerCase() !=
                statusAlreadyReceivedError.toLowerCase(),
          )
          .toList();

      final itemsForPhotoUpload = <UploadSuccessItem>[
        ...uploadData.success,
        ...statusAlreadyReceivedItems.map(
          (f) => UploadSuccessItem(id: f.id, kode: f.kode),
        ),
      ];
      final totalPhotos = itemsForPhotoUpload.length;
      int uploadedPhotos = 0;
      final List<UploadResult> results = [];

      for (final item in itemsForPhotoUpload) {
        final sample = samples.firstWhere((s) => s.dataLsuId == item.id);

        // Update progress
        state = state.copyWith(
          progress: UploadProgress(
            total: totalPhotos,
            current: uploadedPhotos + 1,
            percentage: ((uploadedPhotos + 1) / totalPhotos * 100).round(),
            currentItem: sample.kode,
          ),
        );

        try {
          // Compress image if needed
          String photoPath = sample.fotoPath;
          final compressedPath = await ImageUtils.compressImage(photoPath);
          if (compressedPath != null) {
            photoPath = compressedPath;
          }

          // Upload photo (foto terima)
          final photoResponse = await _api.uploadPhoto(
            filePath: photoPath,
            dataLsuId: item.id,
            kode: item.kode,
            type: 'terima',
            onSendProgress: (sent, total) {
              // Individual photo upload progress could be tracked here
            },
          );

          if (photoResponse.success) {
            // Update status to uploaded
            await _lsuDao.received.updateStatus(
              sample.id!,
              AppConstants.statusUploaded,
            );

            results.add(UploadResult(sample: sample, success: true));
          } else {
            throw Exception(
              photoResponse.error?.message ?? 'Photo upload failed',
            );
          }
        } catch (e) {
          // Update status to error
          await _lsuDao.received.updateStatus(
            sample.id!,
            AppConstants.statusError,
            errorMessage: e.toString(),
          );

          results.add(
            UploadResult(sample: sample, success: false, error: e.toString()),
          );
        }

        uploadedPhotos++;
      }

      // Handle remaining failed items (exclude "Status already received" — those were uploaded above)
      for (final item in otherFailedItems) {
        final sample = samples.firstWhere((s) => s.dataLsuId == item.id);
        await _lsuDao.received.updateStatus(
          sample.id!,
          AppConstants.statusError,
          errorMessage: item.error,
        );

        results.add(
          UploadResult(sample: sample, success: false, error: item.error),
        );
      }

      state = state.copyWith(
        isUploading: false,
        progress: null,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((
  ref,
) {
  return UploadNotifier(ref.watch(uploadApiProvider), ref.watch(lsuDaoProvider));
});

// --- Upload Complete (completed_sample) ---

class CompleteUploadResult {
  final CompletedSample sample;
  final bool success;
  final String? error;

  CompleteUploadResult({
    required this.sample,
    required this.success,
    this.error,
  });
}

class UploadCompleteState {
  final bool isUploading;
  final UploadProgress? progress;
  final List<CompleteUploadResult> results;
  final String? error;

  UploadCompleteState({
    this.isUploading = false,
    this.progress,
    this.results = const [],
    this.error,
  });

  UploadCompleteState copyWith({
    bool? isUploading,
    UploadProgress? progress,
    List<CompleteUploadResult>? results,
    String? error,
  }) {
    return UploadCompleteState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      results: results ?? this.results,
      error: error,
    );
  }
}

class UploadCompleteNotifier extends StateNotifier<UploadCompleteState> {
  final UploadApi _api;
  final LsuDao _lsuDao;

  UploadCompleteNotifier(this._api, this._lsuDao)
      : super(UploadCompleteState());

  Future<void> uploadAllComplete() async {
    state = state.copyWith(isUploading: true, error: null, results: []);

    try {
      final samples = await _lsuDao.completed.getPending();
      if (samples.isEmpty) {
        state = state.copyWith(isUploading: false);
        return;
      }

      final uploadItems = samples.map((s) {
        final fileName = ImageUtils.getFileName(s.fotoPath);
        return CompleteUploadItem(
          id: s.dataLsuId,
          masterLsuId: s.masterLsuId,
          kode: s.kode,
          foto: fileName,
          tanggalSelesai: s.tanggalSelesai,
          waktuSelesai: s.waktuSelesai,
        );
      }).toList();

      final batchResponse =
          await _api.batchUploadComplete(uploadItems);

      if (!batchResponse.success || batchResponse.data == null) {
        state = state.copyWith(
          isUploading: false,
          error: batchResponse.error?.message ?? 'Upload failed',
        );
        return;
      }

      final uploadData = batchResponse.data!;
      const statusAlreadyReceivedError =
          'Status already received, need reupload photo';
      final statusAlreadyReceivedItems = uploadData.failed
          .where(
            (item) =>
                item.error.toLowerCase() ==
                statusAlreadyReceivedError.toLowerCase(),
          )
          .toList();
      final otherFailedItems = uploadData.failed
          .where(
            (item) =>
                item.error.toLowerCase() !=
                statusAlreadyReceivedError.toLowerCase(),
          )
          .toList();

      final itemsForPhotoUpload = <UploadSuccessItem>[
        ...uploadData.success,
        ...statusAlreadyReceivedItems.map(
          (f) => UploadSuccessItem(id: f.id, kode: f.kode),
        ),
      ];
      final totalPhotos = itemsForPhotoUpload.length;
      int uploadedPhotos = 0;
      final List<CompleteUploadResult> results = [];

      for (final item in itemsForPhotoUpload) {
        final sample = samples.firstWhere((s) => s.dataLsuId == item.id);

        state = state.copyWith(
          progress: UploadProgress(
            total: totalPhotos,
            current: uploadedPhotos + 1,
            percentage: ((uploadedPhotos + 1) / totalPhotos * 100).round(),
            currentItem: sample.kode,
          ),
        );

        try {
          String photoPath = sample.fotoPath;
          final compressedPath = await ImageUtils.compressImage(photoPath);
          if (compressedPath != null) {
            photoPath = compressedPath;
          }

          // Upload photo (foto selesai)
          final photoResponse = await _api.uploadPhoto(
            filePath: photoPath,
            dataLsuId: item.id,
            kode: item.kode,
            type: 'selesai',
            onSendProgress: (sent, total) {},
          );

          if (photoResponse.success) {
            await _lsuDao.completed.updateStatus(
              sample.id!,
              AppConstants.statusUploaded,
            );
            results.add(CompleteUploadResult(sample: sample, success: true));
          } else {
            throw Exception(
              photoResponse.error?.message ?? 'Photo upload failed',
            );
          }
        } catch (e) {
          await _lsuDao.completed.updateStatus(
            sample.id!,
            AppConstants.statusError,
            errorMessage: e.toString(),
          );
          results.add(
            CompleteUploadResult(
              sample: sample,
              success: false,
              error: e.toString(),
            ),
          );
        }

        uploadedPhotos++;
      }

      for (final item in otherFailedItems) {
        final sample = samples.firstWhere((s) => s.dataLsuId == item.id);
        await _lsuDao.completed.updateStatus(
          sample.id!,
          AppConstants.statusError,
          errorMessage: item.error,
        );
        results.add(
          CompleteUploadResult(
            sample: sample,
            success: false,
            error: item.error,
          ),
        );
      }

      state = state.copyWith(
        isUploading: false,
        progress: null,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }
}

final uploadCompleteProvider =
    StateNotifierProvider<UploadCompleteNotifier, UploadCompleteState>((ref) {
  return UploadCompleteNotifier(
    ref.watch(uploadApiProvider),
    ref.watch(lsuDaoProvider),
  );
});
