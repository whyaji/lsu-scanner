import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../constants/api_constants.dart';

class FallbackInterceptor extends Interceptor {
  FallbackInterceptor(this._dio);

  final Dio _dio;

  /// Global callback to notify when fallback occurs (e.g., to update the primary Dio instance baseUrl)
  static void Function(String fallbackUrl)? onFallbackDetected;

  bool _isConnectionError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown &&
            (err.message?.contains('SocketException') == true ||
                err.error?.toString().contains('SocketException') == true));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final alreadyRetried =
        requestOptions.extra['__fallback_retry_done__'] == true;

    if (_isConnectionError(err) && !alreadyRetried) {
      final currentBaseUrl = requestOptions.baseUrl;
      final mainBase = ApiConstants.mainBaseUrl;
      final fallbackBase = ApiConstants.fallbackBaseUrl;

      // Check if request was targeting the main API
      if (currentBaseUrl == mainBase ||
          requestOptions.path.startsWith(mainBase)) {
        debugPrint(
          '[FallbackInterceptor] Connection error detected on main API: $currentBaseUrl',
        );
        debugPrint('[FallbackInterceptor] Error: ${err.message ?? err.error}');
        debugPrint(
          '[FallbackInterceptor] Switching globally and retrying with fallback API: $fallbackBase',
        );

        // Update the global active base URL in ApiConstants
        ApiConstants.baseUrl = fallbackBase;

        // Update options on this local Dio instance
        _dio.options.baseUrl = fallbackBase;

        // Notify global listener to update primary client
        onFallbackDetected?.call(fallbackBase);

        // Mark request as retried to prevent infinite loops
        requestOptions.extra['__fallback_retry_done__'] = true;

        if (requestOptions.baseUrl == mainBase) {
          requestOptions.baseUrl = fallbackBase;
        }

        // If path contains the full main URL, replace it
        if (requestOptions.path.startsWith(mainBase)) {
          requestOptions.path = requestOptions.path.replaceFirst(
            mainBase,
            fallbackBase,
          );
        }

        // Rebuild FormData for multipart requests
        final data = requestOptions.data;
        if (data is FormData && data.isFinalized) {
          requestOptions.data = data.clone();
        }

        try {
          // Retry the request using the current Dio instance
          final response = await _dio.fetch(requestOptions);
          handler.resolve(response);
          return;
        } catch (retryError) {
          if (retryError is DioException) {
            handler.next(retryError);
          } else {
            handler.next(
              DioException(
                requestOptions: requestOptions,
                error: retryError,
                type: DioExceptionType.unknown,
              ),
            );
          }
          return;
        }
      }
    }

    handler.next(err);
  }
}
