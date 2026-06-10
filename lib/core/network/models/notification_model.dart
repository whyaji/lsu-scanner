class MobileNotification {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? fcmMessageId;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MobileNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.fcmMessageId,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRead => readAt != null;

  factory MobileNotification.fromJson(Map<String, dynamic> json) {
    return MobileNotification(
      id: json['id'] as int,
      userId: json['userId'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      fcmMessageId: json['fcmMessageId'] as String?,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}

class NotificationsListResponse {
  final List<MobileNotification> notifications;
  final int unreadCount;

  NotificationsListResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] as List<dynamic>? ?? [];
    return NotificationsListResponse(
      notifications: list
          .map((e) => MobileNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
