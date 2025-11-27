// Custom App Bar Widget
import 'package:al_faruk_app/main.dart';
import 'package:al_faruk_app/src/core/theme/theme_provider.dart';
import 'package:al_faruk_app/src/features/notifications/logic/notification_provider.dart';
import 'package:al_faruk_app/src/features/notifications/screens/notification_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Change to ConsumerStatefulWidget to use initState
class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    // 2. Fetch notifications as soon as the App Bar loads
    // Using addPostFrameCallback ensures the provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Watch the unread count
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16.0,
      title: Image.asset('assets/images/logo_symbol.png', height: 36),
      actions: [
        IconButton(
          tooltip: 'Toggle Theme',
          icon: Icon(isDarkMode
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined),
          onPressed: () => themeManager.toggleTheme(),
        ),
        IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_none_outlined),
          ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const NotificationCenterScreen(),
            ));
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
