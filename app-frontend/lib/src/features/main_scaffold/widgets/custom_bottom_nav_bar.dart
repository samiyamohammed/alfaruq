import 'package:flutter/material.dart';
import 'package:al_faruk_app/generated/app_localizations.dart'; // Import

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
    final l10n = AppLocalizations.of(context)!;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.secondary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 4,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled), label: l10n.navHome),
        BottomNavigationBarItem(
            icon: const Icon(Icons.video_library_outlined),
            label: l10n.navVideos),
        BottomNavigationBarItem(
            icon: const Icon(Icons.theaters_outlined), label: l10n.navMovies),
        BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined), label: l10n.navQiblah),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline), label: l10n.navProfile),
      ],
    );
  }
}
