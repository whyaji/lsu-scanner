import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../device_identity.dart';
import '../models/api_response.dart';
import '../models/pupuk_upload_models.dart';
import '../models/upload_models.dart';
import 'api_base.dart';

/// Batch uploads and photo endpoints for both modules.
class UploadApi extends ApiBase {
  const UploadApi(super.dio);

  // --- LSU ---

  Future<ApiResponse<UploadResponse>> batchUpload(
    List<UploadItem> items,
  ) async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.post(
        ApiConstants.batchUpload,
        queryParameters: {'platformId': device['platformId']},
        options: Options(
          headers: {ApiConstants.userAgentHeader: device['userAgent']},
        ),
        data: items.map((e) => e.toJson()).toList(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => UploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<UploadResponse>> batchUploadComplete(
    List<CompleteUploadItem> items,
  ) async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.post(
        ApiConstants.batchUploadComplete,
        queryParameters: {'platformId': device['platformId']},
        options: Options(
          headers: {ApiConstants.userAgentHeader: device['userAgent']},
        ),
        data: items.map((e) => e.toJson()).toList(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => UploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  /// [type] is 'terima' (default) or 'selesai'; the backend uses it to update
  /// the matching Data LSU field.
  Future<ApiResponse<PhotoUploadResponse>> uploadPhoto({
    required String filePath,
    required int dataLsuId,
    required String kode,
    String? type,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'dataLsuId': dataLsuId,
        'kode': kode,
        if (type != null && type.isNotEmpty) 'type': type,
      });

      final response = await dio.post(
        ApiConstants.uploadPhoto,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => PhotoUploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // --- Sampel Pupuk ---

  Future<ApiResponse<SampelPupukUploadResponse>> uploadSampelPupuk(
    SampelPupukUploadPayload payload,
  ) async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.post(
        ApiConstants.uploadSampelPupuk,
        queryParameters: {'platformId': device['platformId']},
        options: Options(
          headers: {ApiConstants.userAgentHeader: device['userAgent']},
        ),
        data: payload.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) =>
            SampelPupukUploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  /// [type] must be one of: kirimDariEstate, kirimLab, kirimSertifikatEstate.
  /// [reuseFilePath] re-links a file already on the server instead of sending
  /// the bytes again.
  Future<ApiResponse<PhotoPupukUploadResponse>> uploadPhotoPupuk({
    required int dataSampelPupukId,
    required String kodeSampel,
    required String type,
    String? filePath,
    String? reuseFilePath,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      if (filePath == null &&
          (reuseFilePath == null || reuseFilePath.isEmpty)) {
        return ApiResponse<PhotoPupukUploadResponse>(
          success: false,
          error: ApiError(
            code: 'VALIDATION_ERROR',
            message: 'filePath or reuseFilePath is required',
          ),
        );
      }
      final map = <String, dynamic>{
        'dataSampelPupukId': dataSampelPupukId,
        'kodeSampel': kodeSampel,
        'type': type,
      };
      if (reuseFilePath != null && reuseFilePath.isNotEmpty) {
        map['reuseFilePath'] = reuseFilePath;
      } else if (filePath != null) {
        map['file'] = await MultipartFile.fromFile(filePath);
      }
      final response = await dio.post(
        ApiConstants.uploadPhotoPupuk,
        data: FormData.fromMap(map),
        onSendProgress: onSendProgress,
      );
      return ApiResponse.fromJson(
        response.data,
        (data) =>
            PhotoPupukUploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  /// One Terima Lab photo; the server path (`/protected/pupuk-lab/...`) goes
  /// into the receipt's `fotoPaths`. [clientUuid] groups the files of a receipt.
  Future<ApiResponse<String>> uploadPhotoPupukLab({
    required String clientUuid,
    required String filePath,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.uploadPhotoPupukLab,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
          'clientUuid': clientUuid,
        }),
        onSendProgress: onSendProgress,
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as Map<String, dynamic>)['filePath'] as String,
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
