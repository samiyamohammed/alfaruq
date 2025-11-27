import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/core/services/settings_service.dart';
import 'package:al_faruk_app/src/core/theme/theme_provider.dart';
import 'package:al_faruk_app/src/features/profile/screens/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  // No local state needed for theme anymore.

  void _showLanguageSelectionDialog(
      BuildContext context, SettingsService settingsService) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.language ?? 'Language';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(title),
          children: settingsService.availableLanguages.entries.map((entry) {
            final localeCode = entry.key;
            final languageName = entry.value;
            return SimpleDialogOption(
              onPressed: () {
                settingsService.setLanguage(localeCode);
                Navigator.pop(context);
              },
              child: Text(languageName),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH SETTINGS
    final settingsService = ref.watch(settingsServiceProvider);
    
    // 2. WATCH THEME (Directly watch the provider)
    final themeManager = ref.watch(themeManagerProvider);

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.appSettings ?? 'App Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n?.language ?? 'Language'),
            subtitle: Text(settingsService
                    .availableLanguages[settingsService.localeCode] ??
                'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSelectionDialog(context, settingsService),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(
              l10n?.theme ?? 'Theme',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode)),
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.sync)),
              ],
              // Use the actual current value from the provider
              selected: {themeManager.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                // Call the method that saves to SharedPreferences
                themeManager.setThemeMode(newSelection.first);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n?.privacyPolicy ?? 'Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}