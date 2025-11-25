import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:al_faruk_app/generated/app_localizations.dart'; // Import

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminderSettings)), // Localized
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.enableAllReminders, // Localized
                style: const TextStyle(fontWeight: FontWeight.bold)),
            value: settings.remindersEnabled,
            onChanged: (value) => ref
                .read(settingsServiceProvider.notifier)
                .setRemindersEnabled(value),
          ),
          const Divider(),
          if (settings.remindersEnabled) ...[
            ListTile(
              title: Text(l10n.notificationBehavior, // Localized
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              title: Text(l10n.reminderSound), // Localized
              value: settings.soundEnabled,
              onChanged: (value) => ref
                  .read(settingsServiceProvider.notifier)
                  .setSoundEnabled(value),
            ),
            if (settings.soundEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: l10n.soundLabel, // Localized
                    border: const OutlineInputBorder(),
                  ),
                  value: settings.selectedSound,
                  items: settings.soundOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      ref
                          .read(settingsServiceProvider.notifier)
                          .setSelectedSound(newValue);
                      _audioPlayer.play(AssetSource('audio/$newValue'));
                    }
                  },
                ),
              ),
            SwitchListTile(
              title: Text(l10n.vibration), // Localized
              value: settings.vibrationEnabled,
              onChanged: (value) => ref
                  .read(settingsServiceProvider.notifier)
                  .setVibrationEnabled(value),
            ),
          ]
        ],
      ),
    );
  }
}
