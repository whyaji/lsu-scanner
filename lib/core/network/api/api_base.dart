import 'package:dio/dio.dart';
import '../models/api_response.dart';

/// Shared Dio holder and error mapping for the per-domain API classes.
abstract class ApiBase {
  const ApiBase(this.dio);

  final Dio dio;

  /// Server error bodies pass through; transport failures become NETWORK_ERROR.
  ApiResponse<T> handleError<T>(DioException e) {
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
