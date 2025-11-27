// lib/src/features/notifications/models/notification_model.dart

import 'package:firebase_messaging/firebase_messaging.dart';

enum NotificationType { general, video }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  // --- 1. From Firebase ---
  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final typeString = data['type'] ?? 'general';

    // FIX 1: Check if 'id' exists in data payload first, otherwise use messageId
    final String id = data['id']?.toString() ??
        message.messageId ??
        DateTime.now().millisecondsSinceEpoch.toString();

    return AppNotification(
      id: id,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: typeString == 'video'
          ? NotificationType.video
          : NotificationType.general,
      // FIX 2: Convert to Local Time
      timestamp: (message.sentTime ?? DateTime.now()).toLocal(),
      isRead: false,
    );
  }

  // --- 2. From Backend API ---
  factory AppNotification.fromApiJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] ?? 'Notification',
      body: json['message'] ?? '',
      type: NotificationType.general,
      // FIX 3: Parse and Convert to Local Time
      timestamp: json['sentAt'] != null
          ? DateTime.parse(json['sentAt']).toLocal()
          : DateTime.now(),
      isRead: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.toString(),
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: json['type'] == 'NotificationType.video'
            ? NotificationType.video
            : NotificationType.general,
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'],
      );
}
