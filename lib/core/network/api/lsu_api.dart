import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../device_identity.dart';
import '../models/api_response.dart';
import '../models/sync_models.dart';
import 'api_base.dart';

class LsuApi extends ApiBase {
  const LsuApi(super.dio);

  /// `GET /mobile/sync-sampel-lsu`; platformId + User-Agent refresh the session.
  Future<ApiResponse<SyncResponse>> syncData(int regional) async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.get(
        ApiConstants.sync,
        queryParameters: {
          'regional': regional,
          'platformId': device['platformId'],
        },
        options: Options(
          headers: {ApiConstants.userAgentHeader: device['userAgent']},
        ),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => SyncResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
