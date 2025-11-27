// lib/src/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED IMPORT

// --- Theme State Management ---
class ThemeManager with ChangeNotifier {
  // Default to System so it matches the user's phone settings
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// 1. LOAD: Call this in main.dart before the app starts
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');

    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// 2. SAVE: Saves the selection to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners(); // Update UI immediately

      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString('theme_mode', 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString('theme_mode', 'dark');
      } else {
        await prefs.setString('theme_mode', 'system');
      }
    }
  }

  // kept for backward compatibility
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

class AppTheme {
  // --- Light Theme Colors ---
  static const Color primaryColor = Color(0xFF1A1A1A); // Dark charcoal
  static const Color accentColor = Color(0xFFD4AF37); // Gold
  static const Color backgroundColor = Colors.white;
  static const Color hintColor = Colors.grey;
  static const Color errorColor = Colors.redAccent;

  // --- Dark Theme Colors ---
  static const Color darkPrimaryColor = Colors.white;
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);

  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: backgroundColor,
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: primaryColor,
        titleTextStyle: GoogleFonts.inter(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        )),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: hintColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: hintColor.withOpacity(0.5), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: errorColor, width: 1.0),
      ),
    ),
  );

  // --- Dark Theme ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackgroundColor,
    primaryColor: darkPrimaryColor,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: darkSurfaceColor,
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        elevation: 1,
        foregroundColor: darkPrimaryColor,
        titleTextStyle: GoogleFonts.inter(
          color: darkPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        )),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
