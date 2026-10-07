import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';
import 'api_base.dart';

class NotificationApi extends ApiBase {
  const NotificationApi(super.dio);

  Future<ApiResponse<NotificationsListResponse>> getNotifications({
    bool unreadOnly = false,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.getNotifications,
        queryParameters: {
          'unreadOnly': unreadOnly,
          'limit': limit,
          'offset': offset,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) =>
            NotificationsListResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> markAsRead(int id) async {
    try {
      final response = await dio.patch(
        ApiConstants.readNotification.replaceAll('{id}', id.toString()),
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> markAllAsRead() async {
    try {
      final response = await dio.patch(ApiConstants.readAllNotifications);
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
