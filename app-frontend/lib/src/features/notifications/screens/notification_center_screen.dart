import 'package:al_faruk_app/src/features/common/screens/guest_restricted_screen.dart'; // Import this
import 'package:al_faruk_app/src/features/notifications/logic/notification_provider.dart';
import 'package:al_faruk_app/src/features/notifications/widgets/notification_list_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the FETCH provider to handle Loading/Error states
    final fetchState = ref.watch(notificationFetchProvider);

    return fetchState.when(
      // A. LOADING STATE
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF0B101D),
        appBar: _buildAppBar(context, ref, []),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFCFB56C)),
        ),
      ),

      // B. ERROR STATE (Handle 403 Guest Access)
      error: (error, stack) {
        if (error is DioException && error.response?.statusCode == 403) {
          // Show the Guest Restricted Screen
          return const GuestRestrictedScreen();
        }

        // Show generic error or fallback to empty state
        return Scaffold(
          backgroundColor: const Color(0xFF0B101D),
          appBar: _buildAppBar(context, ref, []),
          body: Center(
            child: Text("Failed to load notifications: ${error.toString()}",
                style: const TextStyle(color: Colors.white54)),
          ),
        );
      },

      // C. DATA STATE (Show the list)
      data: (_) {
        // Now it's safe to read the list provider because the fetch succeeded
        final notifications = ref.watch(notificationListProvider);

        return Scaffold(
          backgroundColor: const Color(0xFF0B101D),
          appBar: _buildAppBar(context, ref, notifications),
          body: notifications.isEmpty
              ? const Center(
                  child: Text("No notifications",
                      style: TextStyle(color: Colors.white54)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    return Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        ref
                            .read(notificationListProvider.notifier)
                            .clearNotification(notification.id);
                      },
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
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // Extracted AppBar builder to reuse in Loading/Error/Data states
  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, List<dynamic> notifications) {
    return AppBar(
      backgroundColor: const Color(0xFF0B101D),
      elevation: 0,
      leading: const SizedBox.shrink(),
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
