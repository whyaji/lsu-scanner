import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static bool get isDevelopmentMode => kDebugMode;
  // Base URLs
  static String baseUrlDev =
      dotenv.env['BASE_URL_DEV'] ?? 'http://localhost:3000/api';
  static String baseUrlProd =
      dotenv.env['BASE_URL_PROD'] ?? 'https://api.example.com/api';

  // Use development URL by default, change to production in release builds
  static String baseUrl = isDevelopmentMode ? baseUrlDev : baseUrlProd;

  // Endpoints
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String getCurrentUser = '/auth/me';
  static const String sync = '/mobile/sync';
  static const String batchUpload = '/data-lsu/upload';
  static const String uploadPhoto = '/upload/photo';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
}
