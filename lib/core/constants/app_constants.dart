import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  // App Info (loaded from package_info_plus, call init() before use)
  static String _appName = '';
  static String _appVersion = '';
  static String get appName => _appName;
  static String get appVersion => _appVersion;

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _appName = info.appName;
    _appVersion = info.version;
  }

  // Regional
  static const int minRegional = 1;
  static const int maxRegional = 5;
  static const List<int> regionalOptions = [1, 2, 3, 4, 5];

  // Database
  static const String databaseName = 'sampletrack.db';
  static const int databaseVersion = 1;

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyAccessTokenExpiresAt = 'access_token_expires_at';
  static const String keySelectedRegional = 'selected_regional';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyLastSyncSampelPupukTime =
      'last_sync_sampel_pupuk_time';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';

  // Sample Status
  static const String statusNotUploaded = 'not_uploaded';
  static const String statusUploaded = 'uploaded';
  static const String statusError = 'error';

  // Image
  static const int maxImageSizeKB = 100;
  static const int maxImageSizeBytes = maxImageSizeKB * 1024;
  static const int imageCompressQuality = 80;
  static const int imageMaxWidth = 960;
  static const int imageMaxHeight = 720;

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
}

class AppColors {
  static const primary = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF1976D2);
  static const secondary = Color(0xFF03DAC6);
  static const error = Color(0xFFB00020);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}
