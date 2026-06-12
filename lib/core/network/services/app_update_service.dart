import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

/// Result of a user-initiated update check (e.g. from Settings).
enum ManualUpdateOutcome {
  /// iOS or other non-Android platforms.
  platformNotSupported,

  /// Debug builds skip Play in-app updates.
  debugBuild,

  /// No newer version on Play for this install.
  noUpdateAvailable,

  /// Play's immediate-update UI was started.
  updateFlowStarted,

  /// Network or Play Core error.
  error,
}

/// Handles in-app update check and flow (Android only, via Play Core).
/// Call [checkAndUpdate] when the app is ready (e.g. on home screen).
class AppUpdateService {
  AppUpdateService._();

  /// Checks for an update and, if available, performs an immediate update
  /// (full-screen Play dialog). No-op on non-Android and in debug mode.
  static Future<void> checkAndUpdate() async {
    if (!Platform.isAndroid) return;
    if (kDebugMode) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('AppUpdateService: $e');
    }
  }

  /// Same as [checkAndUpdate] but returns an outcome for UI feedback (Settings).
  static Future<ManualUpdateOutcome> manualCheckForUpdate() async {
    if (!Platform.isAndroid) return ManualUpdateOutcome.platformNotSupported;
    if (kDebugMode) return ManualUpdateOutcome.debugBuild;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return ManualUpdateOutcome.noUpdateAvailable;
      }

      await InAppUpdate.performImmediateUpdate();
      return ManualUpdateOutcome.updateFlowStarted;
    } catch (e) {
      debugPrint('AppUpdateService: $e');
      return ManualUpdateOutcome.error;
    }
  }

  /// Checks for an update and, if available, starts a flexible update
  /// (download in background; user can keep using the app).
  /// Call [completeFlexibleUpdate] after download to install.
  static Future<AppUpdateResult?> checkAndStartFlexibleUpdate() async {
    if (!Platform.isAndroid) return null;
    if (kDebugMode) return null;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return null;
      }

      return await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      debugPrint('AppUpdateService: $e');
      return null;
    }
  }

  /// Call after [startFlexibleUpdate] when download is complete to install.
  static Future<void> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('AppUpdateService completeFlexibleUpdate: $e');
    }
  }
}

/// Runs in-app update check when first read (e.g. from [HomeScreen]).
/// No-op on non-Android and in debug mode.
final appUpdateCheckProvider = FutureProvider.autoDispose<void>(
  (ref) => AppUpdateService.checkAndUpdate(),
);
