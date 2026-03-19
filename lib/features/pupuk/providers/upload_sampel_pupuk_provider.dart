import 'package:flutter_riverpod/legacy.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/models/sampel_pupuk_models.dart';
import '../../../core/utils/image_utils.dart';

class UploadSampelPupukProgress {
  final int total;
  final int current;
  final int percentage;
  final String currentItem;

  UploadSampelPupukProgress({
    required this.total,
    required this.current,
    required this.percentage,
    required this.currentItem,
  });
}

class UploadSampelPupukState {
  final bool isUploading;
  final UploadSampelPupukProgress? progress;
  final String? error;

  /// After upload finishes, counts for the result modal (like LSU upload screen).
  final int? lastSuccessCount;
  final int? lastFailedCount;

  UploadSampelPupukState({
    this.isUploading = false,
    this.progress,
    this.error,
    this.lastSuccessCount,
    this.lastFailedCount,
  });

  UploadSampelPupukState copyWith({
    bool? isUploading,
    UploadSampelPupukProgress? progress,
    String? error,
    int? lastSuccessCount,
    int? lastFailedCount,
  }) {
    return UploadSampelPupukState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error,
      lastSuccessCount: lastSuccessCount ?? this.lastSuccessCount,
      lastFailedCount: lastFailedCount ?? this.lastFailedCount,
    );
  }
}

class UploadSampelPupukNotifier extends StateNotifier<UploadSampelPupukState> {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;

  UploadSampelPupukNotifier(this._apiService, this._dbHelper)
    : super(UploadSampelPupukState());

  /// Upload photo with one retry (new request each time). Returns server path on success, null on failure.
  Future<String?> _uploadPhotoWithRetry({
    required String filePath,
    required int dataSampelPupukId,
    required String kodeSampel,
    required String type,
  }) async {
    var path = filePath;
    final compressed = await ImageUtils.compressImage(path);
    if (compressed != null) path = compressed;

    var res = await _apiService.uploadPhotoPupuk(
      filePath: path,
      dataSampelPupukId: dataSampelPupukId,
      kodeSampel: kodeSampel,
      type: type,
    );
    if (res.success && res.data != null) return res.data!.filePath;

    // Retry once (token may have been refreshed by interceptor; new request = new FormData).
    await Future<void>.delayed(const Duration(milliseconds: 400));
    res = await _apiService.uploadPhotoPupuk(
      filePath: path,
      dataSampelPupukId: dataSampelPupukId,
      kodeSampel: kodeSampel,
      type: type,
    );
    if (res.success && res.data != null) return res.data!.filePath;
    return null;
  }

  Future<void> uploadAll() async {
    state = state.copyWith(
      isUploading: true,
      error: null,
      lastSuccessCount: null,
      lastFailedCount: null,
    );

    try {
      final terimaGudang = await _dbHelper.getPendingTerimaDariGudang();
      final kirimEstate = await _dbHelper.getPendingKirimDariEstate();
      final terimaEstate = await _dbHelper.getPendingTerimaDariEstate();
      final kirimLab = await _dbHelper.getPendingKirimLab();
      final kirimSertifikat = await _dbHelper.getPendingKirimSertifikatEstate();

      final total =
          terimaGudang.length +
          kirimEstate.length +
          terimaEstate.length +
          kirimLab.length +
          kirimSertifikat.length;
      if (total == 0) {
        state = state.copyWith(isUploading: false);
        return;
      }

      int done = 0;
      int skippedPhotoFailure = 0;

      final terimaGudangItems = <TerimaDariGudangItem>[];
      for (final row in terimaGudang) {
        state = state.copyWith(
          progress: UploadSampelPupukProgress(
            total: total,
            current: done + 1,
            percentage: ((done + 1) / total * 100).round(),
            currentItem: row.kodeSampel,
          ),
        );
        String? fotoPath = row.fotoTerimaDariGudang;
        if (fotoPath != null && fotoPath.isNotEmpty) {
          final serverPath = await _uploadPhotoWithRetry(
            filePath: fotoPath,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            type: 'terimaDariGudang',
          );
          if (serverPath == null) {
            await _dbHelper.updateTerimaDariGudangStatus(
              row.id!,
              AppConstants.statusError,
              errorMessage: 'Gagal mengunggah foto',
            );
            skippedPhotoFailure++;
            done++;
            continue;
          }
          fotoPath = serverPath;
        }
        terimaGudangItems.add(
          TerimaDariGudangItem(
            id: row.id!,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            tanggalTerimaDariGudang: row.tanggalTerimaDariGudang,
            fotoTerimaDariGudang: fotoPath,
          ),
        );
        done++;
      }

      final kirimEstateItems = <KirimDariEstateItem>[];
      for (final row in kirimEstate) {
        state = state.copyWith(
          progress: UploadSampelPupukProgress(
            total: total,
            current: done + 1,
            percentage: ((done + 1) / total * 100).round(),
            currentItem: row.kodeSampel,
          ),
        );
        String? fotoPath = row.fotoKirimDariEstate;
        if (fotoPath != null && fotoPath.isNotEmpty) {
          final serverPath = await _uploadPhotoWithRetry(
            filePath: fotoPath,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            type: 'kirimDariEstate',
          );
          if (serverPath == null) {
            await _dbHelper.updateKirimDariEstateStatus(
              row.id!,
              AppConstants.statusError,
              errorMessage: 'Gagal mengunggah foto',
            );
            skippedPhotoFailure++;
            done++;
            continue;
          }
          fotoPath = serverPath;
        }
        kirimEstateItems.add(
          KirimDariEstateItem(
            id: row.id!,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            tanggalKirimDariEstate: row.tanggalKirimDariEstate,
            fotoKirimDariEstate: fotoPath,
            namaPengirim: row.namaPengirim,
          ),
        );
        done++;
      }

      final terimaEstateItems = <TerimaDariEstateItem>[];
      for (final row in terimaEstate) {
        state = state.copyWith(
          progress: UploadSampelPupukProgress(
            total: total,
            current: done + 1,
            percentage: ((done + 1) / total * 100).round(),
            currentItem: row.kodeSampel,
          ),
        );
        String? fotoPath = row.fotoTerimaDariEstate;
        if (fotoPath != null && fotoPath.isNotEmpty) {
          final serverPath = await _uploadPhotoWithRetry(
            filePath: fotoPath,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            type: 'terimaDariEstate',
          );
          if (serverPath == null) {
            await _dbHelper.updateTerimaDariEstateStatus(
              row.id!,
              AppConstants.statusError,
              errorMessage: 'Gagal mengunggah foto',
            );
            skippedPhotoFailure++;
            done++;
            continue;
          }
          fotoPath = serverPath;
        }
        terimaEstateItems.add(
          TerimaDariEstateItem(
            id: row.id!,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            tanggalTerimaDariEstate: row.tanggalTerimaDariEstate,
            fotoTerimaDariEstate: fotoPath,
          ),
        );
        done++;
      }

      final kirimLabItems = <KirimLabItem>[];
      for (final row in kirimLab) {
        state = state.copyWith(
          progress: UploadSampelPupukProgress(
            total: total,
            current: done + 1,
            percentage: ((done + 1) / total * 100).round(),
            currentItem: row.kodeSampel,
          ),
        );
        String? fotoPath = row.fotoKirimLab;
        if (fotoPath != null && fotoPath.isNotEmpty) {
          final serverPath = await _uploadPhotoWithRetry(
            filePath: fotoPath,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            type: 'kirimLab',
          );
          if (serverPath == null) {
            await _dbHelper.updateKirimLabStatus(
              row.id!,
              AppConstants.statusError,
              errorMessage: 'Gagal mengunggah foto',
            );
            skippedPhotoFailure++;
            done++;
            continue;
          }
          fotoPath = serverPath;
        }
        kirimLabItems.add(
          KirimLabItem(
            id: row.id!,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            noSurat: row.noSurat,
            tanggalKirimLab: row.tanggalKirimLab,
            fotoKirimLab: fotoPath,
          ),
        );
        done++;
      }

      final kirimSertifikatItems = <KirimSertifikatEstateItem>[];
      for (final row in kirimSertifikat) {
        state = state.copyWith(
          progress: UploadSampelPupukProgress(
            total: total,
            current: done + 1,
            percentage: ((done + 1) / total * 100).round(),
            currentItem: row.kodeSampel,
          ),
        );
        kirimSertifikatItems.add(
          KirimSertifikatEstateItem(
            id: row.id!,
            dataSampelPupukId: row.dataSampelPupukId,
            kodeSampel: row.kodeSampel,
            tanggalKirimSertifikatEstate: row.tanggalKirimSertifikatEstate,
            rekomendasi: row.rekomendasi,
          ),
        );
        done++;
      }

      final payload = SampelPupukUploadPayload(
        terimaDariGudang: terimaGudangItems,
        kirimDariEstate: kirimEstateItems,
        terimaDariEstate: terimaEstateItems,
        kirimLab: kirimLabItems,
        kirimSertifikatEstate: kirimSertifikatItems,
      );

      final response = await _apiService.uploadSampelPupuk(payload);
      if (!response.success || response.data == null) {
        state = state.copyWith(
          isUploading: false,
          progress: null,
          error: response.error?.message ?? 'Upload gagal',
          lastSuccessCount: 0,
          lastFailedCount: total,
        );
        return;
      }

      final data = response.data!;
      int successCount = 0;
      int failedCount = 0;

      for (final s in data.terimaDariGudang.success) {
        await _dbHelper.updateTerimaDariGudangStatus(
          s.id,
          AppConstants.statusUploaded,
        );
        successCount++;
      }
      for (final f in data.terimaDariGudang.failed) {
        await _dbHelper.updateTerimaDariGudangStatus(
          f.id,
          AppConstants.statusError,
          errorMessage: f.error,
        );
        failedCount++;
      }
      for (final s in data.kirimDariEstate.success) {
        await _dbHelper.updateKirimDariEstateStatus(
          s.id,
          AppConstants.statusUploaded,
        );
        successCount++;
      }
      for (final f in data.kirimDariEstate.failed) {
        await _dbHelper.updateKirimDariEstateStatus(
          f.id,
          AppConstants.statusError,
          errorMessage: f.error,
        );
        failedCount++;
      }
      for (final s in data.terimaDariEstate.success) {
        await _dbHelper.updateTerimaDariEstateStatus(
          s.id,
          AppConstants.statusUploaded,
        );
        successCount++;
      }
      for (final f in data.terimaDariEstate.failed) {
        await _dbHelper.updateTerimaDariEstateStatus(
          f.id,
          AppConstants.statusError,
          errorMessage: f.error,
        );
        failedCount++;
      }
      for (final s in data.kirimLab.success) {
        await _dbHelper.updateKirimLabStatus(s.id, AppConstants.statusUploaded);
        successCount++;
      }
      for (final f in data.kirimLab.failed) {
        await _dbHelper.updateKirimLabStatus(
          f.id,
          AppConstants.statusError,
          errorMessage: f.error,
        );
        failedCount++;
      }

      for (final s in data.kirimSertifikatEstate.success) {
        await _dbHelper.updateKirimSertifikatEstateStatus(
          s.id,
          AppConstants.statusUploaded,
        );
        successCount++;
      }
      for (final f in data.kirimSertifikatEstate.failed) {
        await _dbHelper.updateKirimSertifikatEstateStatus(
          f.id,
          AppConstants.statusError,
          errorMessage: f.error,
        );
        failedCount++;
      }

      failedCount += skippedPhotoFailure;

      state = state.copyWith(
        isUploading: false,
        progress: null,
        lastSuccessCount: successCount,
        lastFailedCount: failedCount,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        progress: null,
        error: e.toString(),
      );
    }
  }
}

final uploadSampelPupukProvider =
    StateNotifierProvider<UploadSampelPupukNotifier, UploadSampelPupukState>((
      ref,
    ) {
      final apiService = ApiService(ApiClient().dio);
      final dbHelper = DatabaseHelper.instance;
      return UploadSampelPupukNotifier(apiService, dbHelper);
    });
