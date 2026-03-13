import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'models/api_response.dart';
import 'models/auth_models.dart';
import 'models/sampel_pupuk_models.dart';
import 'models/sync_models.dart';
import 'models/upload_models.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // Auth endpoints
  Future<ApiResponse<LoginResponse>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: LoginRequest(username: username, password: password).toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<RefreshTokenResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => RefreshTokenResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final response = await _dio.post(ApiConstants.logout);
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.getCurrentUser);
      return ApiResponse.fromJson(
        response.data,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Sync endpoint
  Future<ApiResponse<SyncResponse>> syncData(int regional) async {
    try {
      final response = await _dio.get(
        ApiConstants.sync,
        queryParameters: {'regional': regional},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => SyncResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Upload endpoints
  Future<ApiResponse<UploadResponse>> batchUpload(
    List<UploadItem> items,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.batchUpload,
        data: items.map((e) => e.toJson()).toList(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => UploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<UploadResponse>> batchUploadComplete(
    List<CompleteUploadItem> items,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.batchUploadComplete,
        data: items.map((e) => e.toJson()).toList(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => UploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// [type] optional: 'terima' (default) or 'selesai'. Backend uses it to update the correct Data LSU field.
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

      final response = await _dio.post(
        ApiConstants.uploadPhoto,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => PhotoUploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // --- Sampel Pupuk endpoints ---

  Future<ApiResponse<SyncSampelPupukResponse>> syncSampelPupuk(int regional) async {
    try {
      final response = await _dio.get(
        ApiConstants.syncSampelPupuk,
        queryParameters: {'regional': regional},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => SyncSampelPupukResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<int>>> getAreaRegional() async {
    try {
      final response = await _dio.get(ApiConstants.areaRegional);
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List).map((e) => (e as num).toInt()).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<int>>> getAreaWilayah() async {
    try {
      final response = await _dio.get(ApiConstants.areaWilayah);
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List).map((e) => (e as num).toInt()).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<AreaEstateResponse>> getAreaEstate() async {
    try {
      final response = await _dio.get(ApiConstants.areaEstate);
      return ApiResponse.fromJson(
        response.data,
        (data) => AreaEstateResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<SampelPupukUploadResponse>> uploadSampelPupuk(
    SampelPupukUploadPayload payload,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.uploadSampelPupuk,
        data: payload.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => SampelPupukUploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// [type] must be one of: terimaDariGudang, kirimDariEstate, terimaDariEstate, kirimLab.
  Future<ApiResponse<PhotoPupukUploadResponse>> uploadPhotoPupuk({
    required String filePath,
    required int dataSampelPupukId,
    required String kodeSampel,
    required String type,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'dataSampelPupukId': dataSampelPupukId,
        'kodeSampel': kodeSampel,
        'type': type,
      });
      final response = await _dio.post(
        ApiConstants.uploadPhotoPupuk,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => PhotoPupukUploadResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    if (e.response != null) {
      return ApiResponse.fromJson(e.response!.data, null);
    }
    return ApiResponse<T>(
      success: false,
      error: ApiError(
        code: 'NETWORK_ERROR',
        message: e.message ?? 'Network error occurred',
      ),
    );
  }
}
