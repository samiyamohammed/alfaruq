import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YeneMoviesPage extends ConsumerStatefulWidget {
  const YeneMoviesPage({super.key});

  @override
  ConsumerState<YeneMoviesPage> createState() => _YeneMoviesPageState();
}

class _YeneMoviesPageState extends ConsumerState<YeneMoviesPage> {
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 2. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey, // Controls the drawer
      endDrawer: const CustomDrawer(), // The Drawer

      backgroundColor: const Color(0xFF0B101D),

      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.yeneMovie, // Localized Title
        scaffoldKey: _scaffoldKey, // Connects Menu Button
        onLeadingPressed: () {
          ref.read(bottomNavIndexProvider.notifier).state = 0;
        },
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.yourSavedMovies, // Localized "Your saved movies"
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              l10n.swipeToSwitch, // Localized "Swipe left/right..."
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),

          // --- Tabs ---
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: _buildTabButton(l10n.navMovies, Icons.movie_outlined,
                        0)), // Localized "Movies"
                const SizedBox(width: 8),
                Expanded(
                    child: _buildTabButton(l10n.nasheeds,
                        Icons.music_note_outlined, 1)), // Localized "Nasheeds"
                const SizedBox(width: 8),
                Expanded(
                    child: _buildTabButton(l10n.favorites, Icons.star_border,
                        2)), // Localized "Favorites"
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Content PageView ---
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: [
                _buildEmptyState(
                  icon: Icons.lock_outline,
                  message: l10n.noSavedMovies, // Localized
                  subMessage: l10n.addMoviesHint, // Localized
                  buttonLabel: l10n.browseContent, // Localized
                ),
                _buildEmptyState(
                  icon: Icons.music_off_outlined,
                  message: l10n.noSavedNasheeds, // Localized
                  subMessage: l10n.addNasheedsHint, // Localized
                  buttonLabel: l10n.browseContent,
                ),
                _buildEmptyState(
                  icon: Icons.star_border,
                  message: l10n.noFavoritesYet, // Localized
                  subMessage: l10n.markFavoritesHint, // Localized
                  buttonLabel: l10n.browseContent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCFB56C) : const Color(0xFF151E32),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.black : Colors.grey),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String message,
      required String subMessage,
      required String buttonLabel}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: const Color(0xFFCFB56C)),
        const SizedBox(height: 24),
        Text(message,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFB56C),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(buttonLabel,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
