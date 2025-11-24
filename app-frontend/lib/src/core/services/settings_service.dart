// lib/src/core/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  late SharedPreferences _prefs;

  // --- UPDATED LANGUAGE SETTINGS ---
  String _localeCode = 'en'; // Default to English language code
  String get localeCode => _localeCode;

  // Provide a map of language codes to their display names
  final Map<String, String> availableLanguages = {
    'en': 'English',
    'am': 'Amharic',
    'om': 'Afaan Oromo',
  };

  // A new getter to return the current Locale object for MaterialApp
  Locale get currentLocale => Locale(_localeCode);
  // --- END OF UPDATED LANGUAGE SETTINGS ---

  bool _remindersEnabled = true;
  bool _soundEnabled = true;
  String _selectedSound = 'adhan.mp3';
  bool _vibrationEnabled = true;

  bool get remindersEnabled => _remindersEnabled;
  bool get soundEnabled => _soundEnabled;
  String get selectedSound => _selectedSound;
  bool get vibrationEnabled => _vibrationEnabled;

  final Map<String, String> soundOptions = {
    'adhan.mp3': 'Adhan',
    'takbir.mp3': 'Takbir',
    // 'tone.mp3': 'Tone',
  };

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _localeCode = _prefs.getString('languageCode') ?? 'en';
    _remindersEnabled = _prefs.getBool('remindersEnabled') ?? true;
    _soundEnabled = _prefs.getBool('soundEnabled') ?? true;
    _vibrationEnabled = _prefs.getBool('vibrationEnabled') ?? true;

    // --- START OF THE FIX ---
    String savedSound = _prefs.getString('selectedSound') ?? 'adhan.mp3';

    // Check if the saved sound is still in our list of options.
    // If not, fall back to the first available option.
    if (soundOptions.containsKey(savedSound)) {
      _selectedSound = savedSound;
    } else {
      _selectedSound =
          soundOptions.keys.first; // Reset to the first valid sound
    }
    // --- END OF THE FIX ---

    notifyListeners();
  }

  // --- UPDATED METHOD TO SET LANGUAGE ---
  void setLanguage(String newLocaleCode) {
    if (availableLanguages.keys.contains(newLocaleCode)) {
      _localeCode = newLocaleCode;
      _prefs.setString('languageCode', newLocaleCode);
      notifyListeners();
    }
  }

  void setRemindersEnabled(bool value) {
    _remindersEnabled = value;
    _prefs.setBool('remindersEnabled', value);
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _prefs.setBool('soundEnabled', value);
    notifyListeners();
  }

  void setSelectedSound(String soundFile) {
    _selectedSound = soundFile;
    _prefs.setString('selectedSound', soundFile);
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _prefs.setBool('vibrationEnabled', value);
    notifyListeners();
  }
}
