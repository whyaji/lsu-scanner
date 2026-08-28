import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../storage/secure_storage.dart';
import '../device_identity.dart';

class AuthInterceptor extends Interceptor {
  /// Same [Dio] instance the interceptor is attached to — used for 401 retries so
  /// multipart [FormData] can be rebuilt and request interceptors still run.
  AuthInterceptor(this._dio);

  final Dio _dio;
  final SecureStorage _storage = SecureStorage();
  Future<bool>? _refreshFuture;

  /// Optional callback, configured from the auth layer, to clear local
  /// auth state and trigger a logout when refresh can no longer recover
  /// or when the server reports SESSION_CONFLICT (409).
  static Future<void> Function(String message)? _onForceLogout;

  static void configure({
    Future<void> Function(String message)? onForceLogout,
  }) {
    _onForceLogout = onForceLogout;
  }

  static const String _sessionConflictMessage =
      'Akun ini aktif di perangkat lain. Silakan login kembali di perangkat ini.';

  bool _isUnauthenticatedAuthPath(String path) {
    return path.contains('/auth/mobile-login') ||
        path.contains('/auth/mobile-refresh') ||
        path.contains('/auth/refresh');
  }

  /// Sync / LSU upload / pupuk upload may return SESSION_CONFLICT (409 or success:false body).
  static bool isSessionSensitivePath(String path) {
    return path.contains('sync-sampel-lsu') ||
        path.contains('sync-sampel-pupuk') ||
        path.contains('/data-lsu/upload') ||
        path.contains('data-sampel-pupuk/upload');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isUnauthenticatedAuthPath(options.path)) {
      final expiresAtStr = await _storage.getAccessTokenExpiresAt();
      if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
        final expiresAt = int.tryParse(expiresAtStr);
        if (expiresAt != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Refresh if token expires in less than 15 seconds
          if (expiresAt - now < 15000) {
            await _refreshToken(options.baseUrl);
          }
        }
      }

      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final path = response.requestOptions.path;
    if (isSessionSensitivePath(path) && response.data is Map) {
      final map = Map<String, dynamic>.from(response.data as Map);
      if (map['success'] == false) {
        final errMap = map['error'];
        if (errMap is Map && errMap['code']?.toString() == 'SESSION_CONFLICT') {
          final msg = errMap['message'] as String? ?? _sessionConflictMessage;
          if (_onForceLogout != null) {
            await _onForceLogout!(msg);
          }
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // 409 SESSION_CONFLICT (sync/upload / other): clear local session only.
    // Do not call mobile-logout — that would invalidate the legitimate device.
    if (statusCode == 409) {
      final data = err.response?.data;
      if (data is Map) {
        final root = Map<String, dynamic>.from(data);
        final errMap = root['error'];
        if (errMap is Map && errMap['code']?.toString() == 'SESSION_CONFLICT') {
          final nested = Map<String, dynamic>.from(errMap);
          final msg = nested['message'] as String? ?? _sessionConflictMessage;
          if (_onForceLogout != null) {
            await _onForceLogout!(msg);
          }
          handler.next(err);
          return;
        }
      }
    }

    if (statusCode != 401 ||
        _isUnauthenticatedAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final alreadyRetried =
        err.requestOptions.extra['__auth_retry_done__'] == true;
    if (alreadyRetried) {
      await _forceLogoutAndForward(err, handler);
      return;
    }

    final refreshed = await _refreshToken(err.requestOptions.baseUrl);
    if (refreshed) {
      try {
        final token = await _storage.getAccessToken();
        final opts = err.requestOptions;
        final data = opts.data;
        if (data is FormData && data.isFinalized) {
          opts.data = data.clone();
        }
        opts.headers['Authorization'] = token != null
            ? 'Bearer $token'
            : opts.headers['Authorization'];
        opts.extra['__auth_retry_done__'] = true;

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
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    final future = _doRefreshToken(baseUrl);
    _refreshFuture = future;
    try {
      return await future;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefreshToken(String baseUrl) async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final device = await DeviceIdentity.getPlatformIdAndUserAgent();
      final platformId = device['platformId']!;
      final userAgent = device['userAgent']!;

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
          },
        ),
      );
      final response = await dio.post(
        ApiConstants.mobileRefresh,
        data: {'refreshToken': refreshToken, 'platformId': platformId},
        options: Options(
          headers: <String, dynamic>{ApiConstants.userAgentHeader: userAgent},
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final root = response.data as Map<String, dynamic>;
        final ok = root['success'] as bool? ?? true;
        if (!ok) return false;

        final data = root['data'] as Map<String, dynamic>? ?? root;
        final accessToken = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String? ?? refreshToken;
        final expiresIn = (data['expiresIn'] as num?)?.toInt();
        if (accessToken == null || accessToken.isEmpty) return false;

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
