import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';

const int _kMaxLogLines = 10;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson},
      ),
    );

    // Add interceptors (pass _dio so 401 retry uses same client and can resend FormData)
    _dio.interceptors.add(AuthInterceptor());

    // State for truncating response body to first N lines (PrettyDioLogger calls logPrint once per line)
    var inBodySection = false;
    var bodyLinesPrinted = 0;
    var bodyLinesSkipped = 0;

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) {
          final s = obj.toString();
          if (s.startsWith('╔ Body')) {
            inBodySection = true;
            bodyLinesPrinted = 0;
            bodyLinesSkipped = 0;
            debugPrint(s);
            return;
          }
          if (inBodySection) {
            if (s.trimLeft().startsWith('╚')) {
              if (bodyLinesSkipped > 0) {
                debugPrint('║ ... ($bodyLinesSkipped more lines)');
              }
              inBodySection = false;
              debugPrint(s);
              return;
            }
            bodyLinesPrinted++;
            if (bodyLinesPrinted <= _kMaxLogLines) {
              debugPrint(s);
            } else {
              bodyLinesSkipped++;
            }
            return;
          }
          debugPrint(s);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
