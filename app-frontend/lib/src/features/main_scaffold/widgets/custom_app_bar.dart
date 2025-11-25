import 'package:al_faruk_app/main.dart';
import 'package:al_faruk_app/src/core/theme/theme_provider.dart';
import 'package:al_faruk_app/src/features/notifications/screens/notification_center_screen.dart';
// Removed ProfileScreen import as it's no longer needed here
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          icon: const Icon(Icons.notifications_none_outlined),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const NotificationCenterScreen(),
            ));
          },
        ),
        // REMOVED PROFILE BUTTON FROM HERE
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
