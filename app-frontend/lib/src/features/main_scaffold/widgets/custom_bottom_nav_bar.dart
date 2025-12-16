import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1), // Subtle separator
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        // Force the Deep Blue background to match the pages
        backgroundColor: const Color(0xFF0B101D),
        // Gold for selected item
        selectedItemColor: const Color(0xFFCFB56C),
        // Grey for unselected
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: l10n.navHome, // Localized "Home"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.play_circle_outline),
            label: l10n.yeneMovie, // Localized "Yene Movie"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_outlined),
            label: l10n.service, // Localized "Service"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.location_on_outlined),
            label: l10n.khadim, // Localized "Khadim"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            label: l10n.iqra, // Localized "Iqra"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings, // Localized "Settings"
          ),
        ],
      ),
    );
  }
}
