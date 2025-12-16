import 'package:al_faruk_app/src/features/notifications/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine Icon and Color based on broader keywords
    IconData icon;
    Color iconColor;

    // Normalize string for checking
    final String titleLower = notification.title.toLowerCase();
    final String bodyLower = notification.body.toLowerCase();

    // -- LOGIC TO ASSIGN ICONS --
    if (notification.type == NotificationType.video ||
        titleLower.contains('video') ||
        titleLower.contains('youtube') ||
        titleLower.contains('watch')) {
      // Video Content
      icon = Icons.play_circle_fill;
      iconColor = const Color(0xFFFF5252); // Red Accent
    } else if (notification.type == NotificationType.prayer ||
        titleLower.contains('reminder') ||
        titleLower.contains('jumu') || // Jumu'ah
        titleLower.contains('salah') ||
        titleLower.contains('azan') ||
        titleLower.contains('prayer')) {
      // Islamic / Prayer Reminders
      icon = Icons.mosque;
      iconColor = const Color(0xFF1DE9B6); // Teal Accent
    } else if (notification.type == NotificationType.newRelease ||
        titleLower.contains('new feature') ||
        titleLower.contains('update') ||
        titleLower.contains('added')) {
      // App Updates / Features
      icon = Icons.auto_awesome;
      iconColor = const Color(0xFF448AFF); // Blue Accent
    } else {
      // General / Default (Changed from Info to Bell)
      icon = Icons.notifications;
      iconColor = const Color(0xFFCFB56C); // Gold
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151E32), // Dark Card Background
          borderRadius: BorderRadius.circular(12), // Softer corners
          border: Border.all(
            // Unread = Brighter Border, Read = Dim Border
            color: !notification.isRead ? Colors.white38 : Colors.transparent,
            width: 1,
          ),
          boxShadow: !notification.isRead
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Improved Icon Box (No border, soft background)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15), // Soft glow background
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),

            // 3. Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: !notification.isRead
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Optional: Small red dot for unread
                      if (!notification.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCFB56C),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: Colors.grey, // Softer text color
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    timeago.format(notification.timestamp),
                    style: TextStyle(
                      color: iconColor.withOpacity(
                          0.8), // Time matches the icon color slightly
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
