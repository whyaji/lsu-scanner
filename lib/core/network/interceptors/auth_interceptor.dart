import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../../constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage = SecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add token to requests (except sync endpoint)
    if (!options.path.contains('/mobile/sync') &&
        !options.path.contains('/auth/login') &&
        !options.path.contains('/auth/refresh')) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 - refresh token
    if (err.response?.statusCode == 401) {
      try {
        final refreshed = await _refreshToken(err.requestOptions.baseUrl);
        if (refreshed) {
          // Retry request
          final opts = err.requestOptions;
          final token = await _storage.getAccessToken();
          opts.headers['Authorization'] = 'Bearer $token';
          final dio = Dio(BaseOptions(baseUrl: opts.baseUrl));
          final response = await dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        // Refresh failed, continue with error
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken(String baseUrl) async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.saveAccessToken(data['accessToken']);
        final expiresAt = DateTime.now()
            .add(Duration(seconds: data['expiresIn']))
            .millisecondsSinceEpoch;
        await _storage.saveAccessTokenExpiresAt(expiresAt.toString());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
