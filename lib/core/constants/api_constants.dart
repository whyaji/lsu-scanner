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

  // Endpoint LSU Data
  static const String sync = '/mobile/sync';
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
}
