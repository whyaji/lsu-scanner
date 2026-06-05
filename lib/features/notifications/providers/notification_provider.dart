import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/models/notification_model.dart';

class NotificationState {
  final List<MobileNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<MobileNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _apiService;

  NotificationNotifier(this._apiService) : super(NotificationState());

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    final response = await _apiService.getNotifications();
    if (response.success && response.data != null) {
      state = state.copyWith(
        notifications: response.data!.notifications,
        unreadCount: response.data!.unreadCount,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: response.error?.message ?? 'Failed to load notifications',
      );
    }
  }

  Future<void> markAsRead(int id) async {
    // Optimistic update
    final updatedList = state.notifications.map((n) {
      if (n.id == id && n.readAt == null) {
        return MobileNotification(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          fcmMessageId: n.fcmMessageId,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        );
      }
      return n;
    }).toList();

    final unreadDiff =
        state.notifications.any((n) => n.id == id && n.readAt == null) ? 1 : 0;

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: (state.unreadCount - unreadDiff).clamp(0, 999999),
    );

    final response = await _apiService.markNotificationAsRead(id);
    if (!response.success) {
      // Revert/refresh on failure
      fetchNotifications(silent: true);
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final updatedList = state.notifications.map((n) {
      if (n.readAt == null) {
        return MobileNotification(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          fcmMessageId: n.fcmMessageId,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        );
      }
      return n;
    }).toList();

    state = state.copyWith(notifications: updatedList, unreadCount: 0);

    final response = await _apiService.markAllNotificationsAsRead();
    if (!response.success) {
      fetchNotifications(silent: true);
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final apiService = ApiService(ApiClient().dio);
      return NotificationNotifier(apiService);
    });
