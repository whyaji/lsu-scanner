import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../database/models/data_sampel_pupuk.dart';
import '../device_identity.dart';
import '../models/api_response.dart';
import '../models/sync_sampel_pupuk_models.dart';
import 'api_base.dart';

class PupukApi extends ApiBase {
  const PupukApi(super.dio);

  Future<ApiResponse<PaginatedDataSampelPupukResponse>> getDataSampelPupukList({
    int page = 1,
    int limit = 20,
    String? progress,
    String? search,
    String sortBy = 'id',
    String order = 'desc',
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.dataSampelPupuk,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort_by': sortBy,
          'order': order,
          if (progress != null && progress.isNotEmpty) 'progress': progress,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => PaginatedDataSampelPupukResponse.fromJson(
          data as Map<String, dynamic>,
        ),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getDataSampelPupukProgressCounts({
    String? search,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.dataSampelPupukProgressCounts,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => Map<String, dynamic>.from(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<NextNoSuratResponse>> getNextNoSurat() async {
    try {
      final response = await dio.get(ApiConstants.dataSampelPupukNextNoSurat);
      return ApiResponse.fromJson(
        response.data,
        (data) => NextNoSuratResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<DataSampelPupuk>> getDataSampelPupukById(int id) async {
    try {
      final response = await dio.get('${ApiConstants.dataSampelPupuk}/$id');
      return ApiResponse.fromJson(
        response.data,
        (data) => DataSampelPupuk.fromApiJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  /// `GET /mobile/sync-sampel-pupuk`. [regional] is omitted for lab-only users:
  /// the backend returns every regional for them and ignores the parameter.
  Future<ApiResponse<SyncSampelPupukResponse>> syncSampelPupuk({
    int? regional,
  }) async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.get(
        ApiConstants.syncSampelPupuk,
        queryParameters: {
          if (regional != null) 'regional': regional,
          'platformId': device['platformId'],
        },
        options: Options(
          headers: {ApiConstants.userAgentHeader: device['userAgent']},
        ),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) =>
            SyncSampelPupukResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
