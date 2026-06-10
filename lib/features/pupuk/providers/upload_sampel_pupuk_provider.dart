import 'package:flutter_riverpod/legacy.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/database/models/kirim_lab.dart';
import '../../../core/database/models/kirim_sertifikat_estate.dart';
import '../../../core/network/models/api_response.dart';
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

  /// Groups Kirim Lab rows that share the same local foto and/or no. surat (one upload).
  String _kirimLabPhotoGroupKey(KirimLab row) {
    final noSurat = row.noSurat?.trim() ?? '';
    final foto = row.fotoKirimLab?.trim() ?? '';
    if (foto.isEmpty) return 'no-foto:${row.id}';
    if (noSurat.isNotEmpty) return 'batch:$noSurat|$foto';
    return 'foto:$foto';
  }

  Map<String, List<KirimLab>> _groupKirimLabByPhoto(List<KirimLab> rows) {
    final groups = <String, List<KirimLab>>{};
    for (final row in rows) {
      groups.putIfAbsent(_kirimLabPhotoGroupKey(row), () => []).add(row);
    }
    return groups;
  }

  /// Groups rows that share the same local PDF (one Kirim Sertifikat batch).
  String _kirimSertifikatFileGroupKey(KirimSertifikatEstate row) {
    final file = row.fileSertifikat.trim();
    if (file.isEmpty) return 'no-file:${row.id}';
    return 'batch:$file';
  }

  Map<String, List<KirimSertifikatEstate>> _groupKirimSertifikatByFile(
    List<KirimSertifikatEstate> rows,
  ) {
    final groups = <String, List<KirimSertifikatEstate>>{};
    for (final row in rows) {
      groups.putIfAbsent(_kirimSertifikatFileGroupKey(row), () => []).add(row);
    }
    return groups;
  }

  /// Upload photo with one retry. [reuseFilePath] skips file bytes (same batch / no. surat).
  Future<String?> _uploadPhotoWithRetry({
    String? filePath,
    String? reuseFilePath,
    required int dataSampelPupukId,
    required String kodeSampel,
    required String type,
  }) async {
    String? path = filePath;
    if (path != null && path.isNotEmpty) {
      final compressed = await ImageUtils.compressImage(path);
      if (compressed != null) path = compressed;
    }

    Future<ApiResponse<PhotoPupukUploadResponse>> upload() =>
        _apiService.uploadPhotoPupuk(
          filePath: path,
          reuseFilePath: reuseFilePath,
          dataSampelPupukId: dataSampelPupukId,
          kodeSampel: kodeSampel,
          type: type,
        );

    var res = await upload();
    if (res.success && res.data != null) return res.data!.filePath;

    await Future<void>.delayed(const Duration(milliseconds: 400));
    res = await upload();
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
      final kirimEstate = await _dbHelper.getPendingKirimDariEstate();
      final kirimLab = await _dbHelper.getPendingKirimLab();
      final kirimSertifikat = await _dbHelper.getPendingKirimSertifikatEstate();

      final total =
          kirimEstate.length + kirimLab.length + kirimSertifikat.length;
      if (total == 0) {
        state = state.copyWith(isUploading: false);
        return;
      }

      int done = 0;
      int skippedPhotoFailure = 0;

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

      final kirimLabItems = <KirimLabItem>[];
      final kirimLabGroups = _groupKirimLabByPhoto(kirimLab);
      for (final groupRows in kirimLabGroups.values) {
        String? sharedServerFoto;
        final localFoto = groupRows.first.fotoKirimLab?.trim() ?? '';

        if (localFoto.isNotEmpty) {
          final lead = groupRows.first;
          state = state.copyWith(
            progress: UploadSampelPupukProgress(
              total: total,
              current: done + 1,
              percentage: ((done + 1) / total * 100).round(),
              currentItem: groupRows.length > 1
                  ? '${lead.kodeSampel} (+${groupRows.length - 1} sampel)'
                  : lead.kodeSampel,
            ),
          );
          sharedServerFoto = await _uploadPhotoWithRetry(
            filePath: localFoto,
            dataSampelPupukId: lead.dataSampelPupukId,
            kodeSampel: lead.kodeSampel,
            type: 'kirimLab',
          );
          if (sharedServerFoto == null) {
            for (final row in groupRows) {
              await _dbHelper.updateKirimLabStatus(
                row.id!,
                AppConstants.statusError,
                errorMessage: 'Gagal mengunggah foto',
              );
              skippedPhotoFailure++;
              done++;
            }
            continue;
          }
        }

        for (final row in groupRows) {
          state = state.copyWith(
            progress: UploadSampelPupukProgress(
              total: total,
              current: done + 1,
              percentage: ((done + 1) / total * 100).round(),
              currentItem: row.kodeSampel,
            ),
          );
          kirimLabItems.add(
            KirimLabItem(
              id: row.id!,
              dataSampelPupukId: row.dataSampelPupukId,
              kodeSampel: row.kodeSampel,
              noSurat: row.noSurat,
              tanggalKirimLab: row.tanggalKirimLab,
              fotoKirimLab: sharedServerFoto ?? row.fotoKirimLab,
            ),
          );
          done++;
        }
      }

      final kirimSertifikatItems = <KirimSertifikatEstateItem>[];
      final kirimSertifikatGroups = _groupKirimSertifikatByFile(
        kirimSertifikat,
      );
      for (final groupRows in kirimSertifikatGroups.values) {
        String? sharedServerFile;
        final localFile = groupRows.first.fileSertifikat.trim();

        if (localFile.isNotEmpty) {
          final lead = groupRows.first;
          state = state.copyWith(
            progress: UploadSampelPupukProgress(
              total: total,
              current: done + 1,
              percentage: ((done + 1) / total * 100).round(),
              currentItem: groupRows.length > 1
                  ? '${lead.kodeSampel} (+${groupRows.length - 1} sampel)'
                  : lead.kodeSampel,
            ),
          );
          sharedServerFile = await _uploadPhotoWithRetry(
            filePath: localFile,
            dataSampelPupukId: lead.dataSampelPupukId,
            kodeSampel: lead.kodeSampel,
            type: 'kirimSertifikatEstate',
          );
          if (sharedServerFile == null) {
            for (final row in groupRows) {
              await _dbHelper.updateKirimSertifikatEstateStatus(
                row.id!,
                AppConstants.statusError,
                errorMessage: 'Gagal mengunggah file sertifikat',
              );
              skippedPhotoFailure++;
              done++;
            }
            continue;
          }
        }

        for (final row in groupRows) {
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
              fileSertifikat: sharedServerFile ?? row.fileSertifikat,
            ),
          );
          done++;
        }
      }

      final payload = SampelPupukUploadPayload(
        kirimDariEstate: kirimEstateItems,
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
