// lib/src/features/prayer_times/screens/notification_settings_screen.dart

// 1. REMOVE the old provider package import
// import 'package:provider/provider.dart';

// 2. ADD the flutter_riverpod import
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. IMPORT your service providers file where settingsServiceProvider is defined
import 'package:al_faruk_app/src/core/services/service_providers.dart';

import 'package:al_faruk_app/src/core/services/settings_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// 4. CHANGE StatefulWidget to ConsumerStatefulWidget
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  // 5. UPDATE the createState method accordingly
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

// 6. CHANGE State to ConsumerState
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
    // 7. READ the provider using ref.watch (from Riverpod)
    // The 'ref' object is automatically available in a ConsumerState
    final settings = ref.watch(settingsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable All Reminders',
                style: TextStyle(fontWeight: FontWeight.bold)),
            value: settings.remindersEnabled,
            onChanged: (value) => ref
                .read(settingsServiceProvider.notifier)
                .setRemindersEnabled(value),
          ),
          const Divider(),
          if (settings.remindersEnabled) ...[
            const ListTile(
              title: Text('Notification Behavior',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              title: const Text('Reminder Sound'),
              value: settings.soundEnabled,
              onChanged: (value) => ref
                  .read(settingsServiceProvider.notifier)
                  .setSoundEnabled(value),
            ),
            if (settings.soundEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sound',
                    border: OutlineInputBorder(),
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
                      // Use ref.read to call methods on your service/notifier
                      ref
                          .read(settingsServiceProvider.notifier)
                          .setSelectedSound(newValue);
                      _audioPlayer.play(AssetSource('audio/$newValue'));
                    }
                  },
                ),
              ),
            SwitchListTile(
              title: const Text('Vibration'),
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
