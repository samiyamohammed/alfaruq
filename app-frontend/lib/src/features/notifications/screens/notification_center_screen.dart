// lib/src/features/notifications/screens/notification_center_screen.dart
import 'dart:ui';
import 'package:al_faruk_app/src/features/notifications/logic/notification_provider.dart';
import 'package:al_faruk_app/src/features/notifications/models/notification_model.dart';
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
    // --- NEW: Fetch notifications from API when screen opens ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).fetchNotifications();
    });
  }

  Future<void> _showNotificationDetailDialog(
      AppNotification notification) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            title: Text(notification.title),
            content: SingleChildScrollView(
              child: Text(notification.body),
            ),
            actions: <Widget>[
              if (notification.type == NotificationType.video)
                TextButton(
                  child: const Text('Watch Now'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // TODO: Navigate to video player
                  },
                ),
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications yet"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationListItem(
                  notification: notification,
                  onTap: () {
                    ref
                        .read(notificationListProvider.notifier)
                        .markAsRead(notification.id);

                    _showNotificationDetailDialog(notification);
                  },
                );
              },
            ),
    );
  }
}
