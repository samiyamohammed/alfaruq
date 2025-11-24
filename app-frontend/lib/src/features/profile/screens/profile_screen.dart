// lib/src/features/profile/screens/profile_screen.dart
import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart'; // Make sure LoginScreen is imported
import 'package:al_faruk_app/src/features/profile/logic/profile_controller.dart';
import 'package:al_faruk_app/src/features/profile/screens/account_settings_screen.dart';
import 'package:al_faruk_app/src/features/profile/screens/notifications_screen.dart';
import 'package:al_faruk_app/src/features/profile/screens/app_settings_screen.dart';
import 'package:al_faruk_app/src/features/profile/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Log Out'),
              onPressed: () async {
                // 1. Await the logout method to ensure the token is deleted.
                await ref.read(authControllerProvider.notifier).logout();

                // --- THE DEFINITIVE FIX (Your Suggestion) ---
                // 2. Manually navigate to the LoginScreen and remove all previous routes.
                // This is an explicit and reliable way to reset the app's UI state.
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 24),
                profileState.when(
                  loading: () => const Column(
                    children: [
                      CircleAvatar(
                          radius: 50, child: CircularProgressIndicator()),
                      SizedBox(height: 16),
                      Text('Loading...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Please wait',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  error: (error, stackTrace) => Column(
                    children: [
                      const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.error_outline,
                              size: 50, color: Colors.red)),
                      const SizedBox(height: 16),
                      const Text('Error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  data: (user) => Column(
                    children: [
                      const CircleAvatar(
                          radius: 50, child: Icon(Icons.person, size: 50)),
                      const SizedBox(height: 16),
                      Text(user.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                SettingsListTile(
                  icon: Icons.person_outline,
                  title: 'Account Settings',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AccountSettingsScreen()));
                  },
                ),
                SettingsListTile(
                  icon: Icons.notifications_none_outlined,
                  title: 'Prayer Reminders',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()));
                  },
                ),
                SettingsListTile(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AppSettingsScreen()));
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                onPressed: () => _showLogoutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
