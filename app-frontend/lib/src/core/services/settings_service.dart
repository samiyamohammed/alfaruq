import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class SettingsService with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // --- LANGUAGE SETTINGS ---
  String _localeCode = 'en';
  String get localeCode => _localeCode;

  final Map<String, String> availableLanguages = {
    'en': 'English',
    'am': 'Amharic',
    'om': 'Afaan Oromo',
  };

  Locale get currentLocale => Locale(_localeCode);

  // --- NOTIFICATION SETTINGS ---
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
  };

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    _localeCode = _prefs.getString('languageCode') ?? 'en';
    _remindersEnabled = _prefs.getBool('remindersEnabled') ?? true;
    _soundEnabled = _prefs.getBool('soundEnabled') ?? true;
    _vibrationEnabled = _prefs.getBool('vibrationEnabled') ?? true;

    String savedSound = _prefs.getString('selectedSound') ?? 'adhan.mp3';

    if (soundOptions.containsKey(savedSound)) {
      _selectedSound = savedSound;
    } else {
      _selectedSound = soundOptions.keys.first;
    }

    _isInitialized = true;
    notifyListeners();

    // Safety delay to let other init tasks (like NotificationService.init) finish
    Future.delayed(const Duration(milliseconds: 500), () {
      _refreshNotifications();
    });
  }

  // --- SETTERS ---

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
    _refreshNotifications();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _prefs.setBool('soundEnabled', value);
    notifyListeners();
    _refreshNotifications();
  }

  void setSelectedSound(String soundFile) {
    _selectedSound = soundFile;
    _prefs.setString('selectedSound', soundFile);
    notifyListeners();
    _refreshNotifications();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _prefs.setBool('vibrationEnabled', value);
    notifyListeners();
    _refreshNotifications();
  }

  void _refreshNotifications() {
    if (_isInitialized) {
      NotificationService.scheduleDailyPrayerNotifications();
    }
  }
}
