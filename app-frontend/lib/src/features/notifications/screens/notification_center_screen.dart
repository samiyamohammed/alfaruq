import 'package:al_faruk_app/src/features/notifications/logic/notification_provider.dart';
import 'package:al_faruk_app/src/features/notifications/widgets/notification_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D), // Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B101D),
        elevation: 0,
        leading: const SizedBox.shrink(), // Custom layout
        leadingWidth: 0,
        title: Row(
          children: [
            const Icon(Icons.notifications_none, color: Color(0xFFCFB56C)),
            const SizedBox(width: 8),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            if (notifications.isNotEmpty)
              GestureDetector(
                onTap: () {
                  ref.read(notificationListProvider.notifier).clearAll();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Clear All",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text("No notifications",
                  style: TextStyle(color: Colors.white54)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Dismissible(
                  key: Key(notification.id),
                  // Swipe LEFT or RIGHT to clear
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    ref
                        .read(notificationListProvider.notifier)
                        .clearNotification(notification.id);
                  },
                  // Swipe Background (Red Trash Icon)
                  background: _buildSwipeBackground(Alignment.centerLeft),
                  secondaryBackground:
                      _buildSwipeBackground(Alignment.centerRight),
                  child: NotificationListItem(
                    notification: notification,
                    onTap: () {
                      if (!notification.isRead) {
                        ref
                            .read(notificationListProvider.notifier)
                            .markAsRead(notification.id);
                      }
                      // You can add navigation here if needed (e.g., to Video Player)
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSwipeBackground(Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}
