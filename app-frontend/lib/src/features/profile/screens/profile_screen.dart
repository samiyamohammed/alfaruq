import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart';
import 'package:al_faruk_app/src/features/profile/logic/profile_controller.dart';
import 'package:al_faruk_app/src/features/profile/screens/account_settings_screen.dart';
import 'package:al_faruk_app/src/features/profile/screens/notifications_screen.dart';
import 'package:al_faruk_app/src/features/profile/screens/app_settings_screen.dart';
import 'package:al_faruk_app/src/features/profile/widgets/settings_list_tile.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/generated/app_localizations.dart'; // Import

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.logOut), // Localized
          content: Text(l10n.logOutConfirmation), // Localized
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel), // Localized
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(l10n.logOut), // Localized
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 24),
                profileState.when(
                  loading: () => Column(
                    children: [
                      const CircleAvatar(
                          radius: 50, child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                      Text(l10n.loading, // Localized
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(l10n.pleaseWait, // Localized
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  error: (error, stackTrace) => Column(
                    children: [
                      const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.error_outline,
                              size: 50, color: Colors.red)),
                      const SizedBox(height: 16),
                      Text(l10n.error, // Localized
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
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
                  title: l10n.accountSettings, // Localized
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AccountSettingsScreen()));
                  },
                ),
                SettingsListTile(
                  icon: Icons.notifications_none_outlined,
                  title: l10n.prayerReminders, // Localized
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()));
                  },
                ),
                SettingsListTile(
                  icon: Icons.settings_outlined,
                  title: l10n.appSettings, // Localized
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
                label: Text(l10n.logOut), // Localized
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
