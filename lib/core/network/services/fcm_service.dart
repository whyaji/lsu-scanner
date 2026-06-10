import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';
import '../../network/api_client.dart';
import '../../network/api_service.dart';
import '../../services/notification_sound_service.dart';
import '../../../features/notifications/providers/notification_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling a background message: ${message.messageId}');
}

class FcmService {
  final Ref _ref;
  final ApiService _apiService;
  bool _initialized = false;

  FcmService(this._ref) : _apiService = ApiService(ApiClient().dio);

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

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
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        log('FCM Token: $token');
        final response = await _apiService.updateFcmToken(token);
        if (response.success) {
          log('FCM Token uploaded successfully.');
        } else {
          log('Failed to upload FCM Token: ${response.error?.message}');
        }
      }
    } catch (e) {
      log('Error getting/uploading FCM Token: $e');
    }
  }

  void _handleMessageClick(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.pushNamed('/notifications');
    });
  }

  void _showForegroundBanner(RemoteMessage message) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.notification?.title ?? 'Notification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.notification?.body ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: () {
            appNavigatorKey.currentState?.pushNamed('/notifications');
          },
        ),
      ),
    );
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});
