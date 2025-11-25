// lib/src/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Theme State Management ---
// This small class will manage and notify the app of theme changes.
class ThemeManager with ChangeNotifier {
  // Defaulting to System is usually better UX, but I kept Light to match your previous code.
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // 1. NEW METHOD: Allows setting specific modes (Light, Dark, System)
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // kept for backward compatibility if used elsewhere
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
  static const Color accentColor = Color(0xFFD4AF37);  // Gold
  static const Color backgroundColor = Colors.white;
  static const Color hintColor = Colors.grey;
  static const Color errorColor = Colors.redAccent;

  // --- Dark Theme Colors (NEW) ---
  static const Color darkPrimaryColor = Colors.white; // Text color for dark mode
  static const Color darkBackgroundColor = Color(0xFF121212); // Deep dark background
  static const Color darkSurfaceColor = Color(0xFF1E1E1E); // Color for cards, app bars

  // --- Light Theme (Existing) ---
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
        )
    ),
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

  // --- Dark Theme (NEW) ---
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
        )
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData( // Keep buttons consistent
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Using light primary for button bg
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    // You can add dark theme specific input decorations if needed
  );
}