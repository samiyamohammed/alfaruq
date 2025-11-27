import 'package:al_faruk_app/src/features/notifications/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.video:
        return Icons.play_circle_outline;
      case NotificationType.general:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Format timestamp (e.g., "Nov 26, 2025 3:30 PM")
    final timeAgo = DateFormat.yMMMd().add_jm().format(notification.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isUnread ? 2 : 0,
      color: isUnread
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
          : Theme.of(context).cardColor,
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            Icon(
              _getIconForType(notification.type),
              size: 30,
              color: isUnread
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            if (isUnread)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5),
                ),
              )
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    // FIX: Make text darker in Light Mode for better visibility
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
