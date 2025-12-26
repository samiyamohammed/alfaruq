import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/features/auth/logic/login_controller.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:al_faruk_app/src/features/prayer_times/screens/notification_settings_screen.dart';
import 'package:al_faruk_app/src/features/profile/screens/privacy_policy_screen.dart';
import 'package:al_faruk_app/src/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- FIX IS HERE ---
  void _showLanguageSelectionDialog(
      BuildContext context, dynamic settingsService) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF151E32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.selectLanguage,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...settingsService.availableLanguages.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.value,
                        style: const TextStyle(color: Colors.white)),
                    leading:
                        const Icon(Icons.language, color: Color(0xFFCFB56C)),
                    onTap: () async {
                      // 1. Close the Dialog FIRST
                      Navigator.of(dialogContext).pop();

                      // 2. Wait a tiny bit (200ms) for the dialog to fully close
                      // This prevents the "Red Screen" crash by separating the UI update from the Logic update
                      await Future.delayed(const Duration(milliseconds: 200));

                      // 3. NOW change the language
                      settingsService.setLanguage(entry.key);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

// ... inside your screen class ...

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;

    // 1. Show Confirmation
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151E32),
          title: Text(l10n.logOut, style: const TextStyle(color: Colors.white)),
          content: Text(
            l10n.logOutConfirmation,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel,
                  style: const TextStyle(color: Colors.white54)),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(l10n.logOut,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    // 2. Perform Logout
    if (shouldLogout == true && mounted) {
      // Show Non-Dismissible Loading Spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
      );

      try {
        // Safe Logout Call (Controller now handles popping the spinner)
        await ref.read(loginControllerProvider.notifier).logout(context);
      } catch (e) {
        // In case of error, make sure we pop the spinner so user isn't stuck
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Logout failed: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = ref.watch(settingsServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.settings,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            ref.read(bottomNavIndexProvider.notifier).state = 0;
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.managePreferences,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // --- ACCOUNT SECTION ---
            _buildSectionHeader(l10n.sectionAccount),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151E32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.person_outline,
                    title: l10n.generalSettingsTile,
                    subtitle: l10n.profilePasswordMore,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()));
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildSettingTile(
                    icon: Icons.notifications_none,
                    title: l10n.notificationSettings,
                    subtitle: l10n.manageNotificationPreferences,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const NotificationSettingsScreen()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- APP SECTION ---
            _buildSectionHeader(l10n.sectionApp),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151E32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.language,
                    title: l10n.appLanguage,
                    subtitle: settingsService
                            .availableLanguages[settingsService.localeCode] ??
                        'English',
                    onTap: () =>
                        _showLanguageSelectionDialog(context, settingsService),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildSettingTile(
                    icon: Icons.shield_outlined,
                    title: l10n.privacySecurity,
                    subtitle: l10n.managePrivacy,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- OTHER SECTION ---
            _buildSectionHeader(l10n.sectionOther),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151E32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: l10n.about,
                    subtitle: "Version 1.0.0",
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFCFB56C)),
                    title: Text(l10n.logOut,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(l10n.signOutSubtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _handleLogout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFCFB56C)),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
