import 'package:firebase_messaging/firebase_messaging.dart';

enum NotificationType { general, video, prayer, newRelease }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  // --- 1. CopyWith Method (Added this to fix your error) ---
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // --- 2. From Firebase ---
  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final typeString = data['type']?.toString().toLowerCase() ?? 'general';

    final String id = data['id']?.toString() ??
        message.messageId ??
        DateTime.now().millisecondsSinceEpoch.toString();

    return AppNotification(
      id: id,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: _parseType(typeString),
      timestamp: (message.sentTime ?? DateTime.now()).toLocal(),
      isRead: false,
    );
  }

  // --- 3. From Backend API ---
  factory AppNotification.fromApiJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] ?? 'Notification',
      body: json['message'] ?? json['body'] ?? '',
      type: _parseType(json['type']?.toString() ?? ''),
      // Parse sentAt or timestamp
      timestamp: json['sentAt'] != null
          ? DateTime.parse(json['sentAt']).toLocal()
          : (json['timestamp'] != null
              ? DateTime.parse(json['timestamp']).toLocal()
              : DateTime.now()),
      isRead: json['isRead'] ?? false,
    );
  }

  // Helper to parse types based on keywords or exact matches
  static NotificationType _parseType(String typeStr) {
    final t = typeStr.toLowerCase();
    if (t.contains('video') || t.contains('youtube'))
      return NotificationType.video;
    if (t.contains('prayer') || t.contains('azan'))
      return NotificationType.prayer;
    if (t.contains('release') || t.contains('movie'))
      return NotificationType.newRelease;
    return NotificationType.general;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.toString(),
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Handle string enum storage
    NotificationType storedType = NotificationType.general;
    if (json['type'].toString().contains('video'))
      storedType = NotificationType.video;
    else if (json['type'].toString().contains('prayer'))
      storedType = NotificationType.prayer;
    else if (json['type'].toString().contains('Release'))
      storedType = NotificationType.newRelease;

    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: storedType,
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
    );
  }
}
