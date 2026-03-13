import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../../constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  final SecureStorage _storage = SecureStorage();

  /// Optional callback, configured from the auth layer, to clear local
  /// auth state and trigger a logout when refresh can no longer recover.
  static Future<void> Function(String message)? _onForceLogout;

  /// Serialize token refresh: only one refresh at a time; others wait and retry.
  static Future<bool>? _refreshFuture;

  static void configure({
    Future<void> Function(String message)? onForceLogout,
  }) {
    _onForceLogout = onForceLogout;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach Bearer token to all requests except auth endpoints.
    if (!options.path.contains('/auth/login') &&
        !options.path.contains('/auth/refresh')) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // Only handle 401 here; let other errors pass through.
    if (statusCode != 401 ||
        err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/refresh')) {
      handler.next(err);
      return;
    }

    // Avoid infinite loops: don't retry a request we've already retried.
    final alreadyRetried =
        err.requestOptions.extra['__auth_retry_done__'] == true;
    if (alreadyRetried) {
      await _forceLogoutAndForward(err, handler);
      return;
    }

    // Serialize refresh: if another request is already refreshing, wait for it.
    final refreshed = await _refreshTokenSerialized(err.requestOptions.baseUrl);
    if (refreshed) {
      try {
        final token = await _storage.getAccessToken();
        final opts = err.requestOptions;
        opts.headers['Authorization'] = token != null
            ? 'Bearer $token'
            : opts.headers['Authorization'];
        opts.extra['__auth_retry_done__'] = true;

        // FormData is finalized after first send; clone so the retry can send the body again.
        if (opts.data is FormData) {
          opts.data = (opts.data as FormData).clone();
        }

        final response = await _dio.fetch(opts);
        handler.resolve(response);
        return;
      } catch (_) {
        await _forceLogoutAndForward(err, handler);
        return;
      }
    } else {
      await _forceLogoutAndForward(err, handler);
    }
  }

  /// Ensures only one refresh runs at a time; concurrent 401s wait for the same refresh.
  Future<bool> _refreshTokenSerialized(String baseUrl) async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _refreshToken(baseUrl);
    try {
      final result = await _refreshFuture!;
      return result;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _forceLogoutAndForward(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    const expiredMessage =
        'Sesi login Anda telah berakhir. Silakan login kembali.';
    if (_onForceLogout != null) {
      await _onForceLogout!(expiredMessage);
    }
    final fakeResponse = Response<dynamic>(
      requestOptions: err.requestOptions,
      statusCode: 401,
      data: {
        'success': false,
        'error': {'code': 'UNAUTHORIZED', 'message': expiredMessage},
      },
    );
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: fakeResponse,
        type: DioExceptionType.badResponse,
      ),
    );
  }

  Future<bool> _refreshToken(String baseUrl) async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          (response.data['success'] as bool? ?? true)) {
        final data =
            response.data['data'] as Map<String, dynamic>? ??
            response.data as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String? ?? refreshToken;
        final expiresIn = (data['expiresIn'] as num?)?.toInt();
        if (accessToken == null) return false;

        await _storage.saveAccessToken(accessToken);
        await _storage.saveRefreshToken(newRefresh);
        if (expiresIn != null) {
          final expiresAt = DateTime.now()
              .add(Duration(seconds: expiresIn))
              .millisecondsSinceEpoch;
          await _storage.saveAccessTokenExpiresAt(expiresAt.toString());
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
