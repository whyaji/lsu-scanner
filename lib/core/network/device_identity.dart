import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../constants/app_constants.dart';

/// Stable device id + User-Agent for mobile session APIs (login, refresh, logout, sync).
class DeviceIdentity {
  DeviceIdentity._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, String>> getPlatformIdAndUserAgent() async {
    String platformId = 'unknown';
    String userAgent = 'poh-mobile/unknown (platform=unknown)';

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final androidId = info.id;
        final model = info.model;
        final brand = info.brand;
        final osVersion = info.version.release;
        platformId = androidId;
        userAgent =
            '${AppConstants.appName}/${AppConstants.appVersion} android (brand=$brand; model=$model; osVersion=$osVersion; androidId=$androidId)';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final idfv = info.identifierForVendor ?? 'unknown';
        final model = info.utsname.machine;
        final osVersion = info.systemVersion;
        platformId = idfv;
        userAgent =
            '${AppConstants.appName}/${AppConstants.appVersion} ios (model=$model; osVersion=$osVersion; idfv=$idfv)';
      }
    } catch (_) {
      // Keep defaults
    }

    return <String, String>{'platformId': platformId, 'userAgent': userAgent};
  }
}
