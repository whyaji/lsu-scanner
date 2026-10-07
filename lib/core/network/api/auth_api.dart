import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../device_identity.dart';
import '../models/api_response.dart';
import '../models/auth_models.dart';
import 'api_base.dart';

class AuthApi extends ApiBase {
  const AuthApi(super.dio);

  /// `POST /auth/mobile-login` with platformId and userAgent.
  Future<ApiResponse<LoginResponse>> login(
    String username,
    String password,
  ) async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.post(
        ApiConstants.login,
        data: LoginRequest(
          username: username,
          password: password,
          platformId: device['platformId']!,
          userAgent: device['userAgent']!,
        ).toJson(),
        options: Options(
          headers: {ApiConstants.userAgentHeader: device['userAgent']!},
        ),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<MobileRefreshResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.post(
        ApiConstants.mobileRefresh,
        data: RefreshTokenRequest(
          refreshToken: refreshToken,
          platformId: device['platformId']!,
        ).toJson(),
        options: Options(
          headers: {ApiConstants.userAgentHeader: device['userAgent']!},
        ),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => MobileRefreshResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  /// Ends the mobile session on the server (Bearer + body).
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final response = await dio.post(
        ApiConstants.mobileLogout,
        data: MobileLogoutRequest(
          platformId: device['platformId']!,
          userAgent: device['userAgent']!,
        ).toJson(),
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await dio.get(ApiConstants.getCurrentUser);
      return ApiResponse.fromJson(
        response.data,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateFcmToken(
    String fcmToken,
  ) async {
    try {
      final response = await dio.post(
        ApiConstants.updateFcmToken,
        data: {'fcmToken': fcmToken},
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
