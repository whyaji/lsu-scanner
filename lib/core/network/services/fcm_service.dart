import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';
import '../api_providers.dart';
import '../../services/notification_sound_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/utils/notification_navigation.dart';
import '../../../features/regional/providers/regional_provider.dart';
import '../../database/database_providers.dart';
import '../../../widgets/feedback/app_notice_type.dart';
import '../../../widgets/feedback/app_toast.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling a background message: ${message.messageId}');
}

class FcmService {
  final Ref _ref;
  bool _initialized = false;
  bool _tapListenersRegistered = false;
  RemoteMessage? _pendingTapMessage;

  FcmService(this._ref);

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      _registerTapListeners();

      // Set up foreground notification presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Request permission
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      log(
        'User granted notification permission: ${settings.authorizationStatus}',
      );

      // Get initial message (app opened from terminated state by notification click)
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageClick(initialMessage);
      }

      // Listen to active notifications when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');
        log('Message data: ${message.data}');

        if (message.notification != null) {
          log(
            'Message also contained a notification: ${message.notification!.title}',
          );
          NotificationSoundService.instance.play(message.data['sound']);
          _showForegroundBanner(message);
        }

        // Refresh notifications list provider
        _ref
            .read(notificationProvider.notifier)
            .fetchNotifications(silent: true);
      });

      // Listen to notification clicks when app is in background (but running)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('Notification clicked!');
        _handleMessageClick(message);
      });

      _initialized = true;

      // Update token on start if authenticated
      await uploadToken();
    } catch (e, stack) {
      log(
        'Error initializing Firebase Messaging: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> uploadToken() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      log('Skipping FCM token upload: User is not authenticated.');
      return;
    }

    final userId = auth.user?.userId;
    if (userId == null) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final preferencesDao = _ref.read(preferencesDaoProvider);
        final cacheKey = 'fcm_token_$userId';
        final cachedToken = await preferencesDao.get(cacheKey);

        if (cachedToken == token) {
          log('FCM Token is already up to date for user $userId.');
          return;
        }

        log('FCM Token: $token');
        final response = await _ref.read(authApiProvider).updateFcmToken(token);
        if (response.success) {
          log('FCM Token uploaded successfully.');
          await preferencesDao.set(cacheKey, token);
        } else {
          log('Failed to upload FCM Token: ${response.error?.message}');
        }
      }
    } catch (e) {
      log('Error getting/uploading FCM Token: $e');
    }
  }

  void _registerTapListeners() {
    if (_tapListenersRegistered) return;
    _tapListenersRegistered = true;

    _ref.listen<AuthState>(authProvider, (previous, next) {
      processPendingNotificationTap();
    });
    _ref.listen<RegionalState>(regionalProvider, (previous, next) {
      processPendingNotificationTap();
    });
  }

  bool _isAppReadyForNotificationNavigation() {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated || auth.isLoading) return false;

    final regional = _ref.read(regionalProvider);
    if (_ref.read(regionalRequiredProvider) &&
        regional.selectedRegional == null) {
      return false;
    }

    return appNavigatorKey.currentState != null;
  }

  void _handleMessageClick(RemoteMessage message) {
    log(
      'Notification tap queued: id=${message.messageId}, data=${message.data}',
    );
    _pendingTapMessage = message;
    processPendingNotificationTap();
  }

  /// Navigate to the screen for a notification tap once auth + navigator are ready.
  void processPendingNotificationTap({int attempt = 0}) {
    final message = _pendingTapMessage;
    if (message == null) return;

    if (!_isAppReadyForNotificationNavigation()) {
      if (attempt < 120) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          processPendingNotificationTap(attempt: attempt + 1);
        });
      }
      return;
    }

    final context = appNavigatorKey.currentContext;
    final nav = appNavigatorKey.currentState;
    if (context == null || nav == null) {
      if (attempt < 120) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          processPendingNotificationTap(attempt: attempt + 1);
        });
      }
      return;
    }

    _pendingTapMessage = null;

    final data = Map<String, dynamic>.from(message.data);
    final title =
        message.notification?.title ??
        data['title']?.toString() ??
        'Notifikasi';
    final body = message.notification?.body ?? data['body']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      if (parseNotificationSampleIds(data).isNotEmpty) {
        await openNotificationDataTarget(
          context,
          data,
          title: title,
          body: body,
          type: type,
        );
        return;
      }

      await nav.pushNamed('/notifications');
    });
  }

  void _showForegroundBanner(RemoteMessage message) {
    AppToast.showGlobal(
      message.notification?.body ?? 'Ada notifikasi baru.',
      type: AppNoticeType.info,
      actionLabel: 'Lihat',
      onAction: () => _handleMessageClick(message),
    );
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});
