// lib/src/features/profile/screens/app_settings_screen.dart
import 'package:al_faruk_app/main.dart';
import 'package:al_faruk_app/src/core/services/settings_service.dart';
import 'package:al_faruk_app/src/core/theme/theme_provider.dart';
import 'package:al_faruk_app/src/features/profile/screens/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// --- 1. IMPORT THE GENERATED LOCALIZATION FILE ---
import 'package:al_faruk_app/generated/app_localizations.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  ThemeMode _selectedTheme = themeManager.themeMode;

  void _showLanguageSelectionDialog(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          // --- USE TRANSLATED TEXT ---
          title: Text(AppLocalizations.of(context)!.language),
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
    final settingsService = Provider.of<SettingsService>(context);
    // --- GET LOCALIZATION INSTANCE ---
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // --- USE TRANSLATED TEXT ---
      appBar: AppBar(title: Text(l10n.appSettings)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            // --- USE TRANSLATED TEXT ---
            title: Text(l10n.language),
            // Display the name of the currently selected language
            subtitle: Text(settingsService.availableLanguages[settingsService.localeCode]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSelectionDialog(context, settingsService),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            // --- USE TRANSLATED TEXT ---
            title: Text(l10n.theme, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.sync)),
              ],
              selected: {_selectedTheme},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                setState(() {
                  _selectedTheme = newSelection.first;
                  if (_selectedTheme == ThemeMode.light && themeManager.themeMode != ThemeMode.light) {
                    themeManager.toggleTheme();
                  } else if (_selectedTheme == ThemeMode.dark && themeManager.themeMode != ThemeMode.dark) {
                    themeManager.toggleTheme();
                  }
                });
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            // --- USE TRANSLATED TEXT ---
            title: Text(l10n.privacyPolicy),
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