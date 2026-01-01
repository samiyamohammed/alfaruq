import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors from Screenshots ---
  static const Color primaryColor = Color(0xFFCFB56C); // Gold
  static const Color scaffoldBackgroundColor =
      Color(0xFF0B101D); // Deep Midnight Blue
  static const Color surfaceColor =
      Color(0xFF151E32); // Slightly lighter blue for cards
  static const Color whiteColor = Colors.white;
  static const Color greyColor = Colors.grey;

  // --- The Single Fixed Theme ---
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    primaryColor: primaryColor,
    useMaterial3: true,

    // EXPERT FIX: Eliminate flickering background state on click
    // We set these to transparent so clicking a button doesn't create a grey/white flash
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: surfaceColor,
      onSurface: whiteColor,
      background: scaffoldBackgroundColor,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: whiteColor),
      titleTextStyle: GoogleFonts.inter(
        color: whiteColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Bottom Nav Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: scaffoldBackgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: greyColor,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 10,
    ),

    // Text Theme
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: whiteColor,
      displayColor: whiteColor,
    ),

    // Elevated Button Theme (Adjusted for smooth non-flicker clicks)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0, // Lower elevation reduces visual "pop" flickering
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Icon Button Fix (To stop the circular grey flicker)
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
    ),
  );
}
