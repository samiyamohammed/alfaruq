import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.notificationSettings,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: const Color(0xFFCFB56C),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    l10n.enableAllReminders,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: settings.remindersEnabled,
                  onChanged: (value) => ref
                      .read(settingsServiceProvider.notifier)
                      .setRemindersEnabled(value),
                ),
                if (settings.remindersEnabled) ...[
                  const Divider(height: 1, color: Colors.white10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.notificationBehavior,
                        style: const TextStyle(
                          color: Color(0xFFCFB56C),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    activeColor: const Color(0xFFCFB56C),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      l10n.reminderSound,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: settings.soundEnabled,
                    onChanged: (value) => ref
                        .read(settingsServiceProvider.notifier)
                        .setSoundEnabled(value),
                  ),
                  if (settings.soundEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF151E32),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: l10n.soundLabel,
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFCFB56C)),
                          ),
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
                            // Preview play in app
                            _audioPlayer.play(AssetSource('audio/$newValue'));
                          }
                        },
                      ),
                    ),
                  SwitchListTile(
                    activeColor: const Color(0xFFCFB56C),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      l10n.vibration,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: settings.vibrationEnabled,
                    onChanged: (value) => ref
                        .read(settingsServiceProvider.notifier)
                        .setVibrationEnabled(value),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
