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

  static const String login = '/auth/mobile-login';
  static const String mobileRefresh = '/auth/mobile-refresh';
  static const String mobileLogout = '/auth/mobile-logout';
  static const String getCurrentUser = '/auth/me';
  static const String updateFcmToken = '/auth/mobile-fcm-token';
  static const String getNotifications = '/notifications';
  static const String readNotification = '/notifications/{id}/read';
  static const String readAllNotifications = '/notifications/read-all';

  // Endpoint LSU Data
  static const String sync = '/mobile/sync-sampel-lsu';
  static const String batchUpload = '/data-lsu/upload';
  static const String batchUploadComplete = '/data-lsu/upload-complete';
  static const String uploadPhoto = '/upload/photo';

  // Endpoint Sampel Pupuk (Fertilizer)
  static const String syncSampelPupuk = '/mobile/sync-sampel-pupuk';
  static const String areaRegional = '/area/regional';
  static const String areaWilayah = '/area/wilayah';
  static const String areaEstate = '/area/estate';
  static const String uploadSampelPupuk = '/data-sampel-pupuk/upload';
  static const String uploadPhotoPupuk = '/upload/photo-pupuk';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
  static const String userAgentHeader = 'User-Agent';
}
