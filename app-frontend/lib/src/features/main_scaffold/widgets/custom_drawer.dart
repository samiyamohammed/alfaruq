import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/generic_grid_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/news_feed_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/tafsir_sheikhs_screen.dart';
import 'package:al_faruk_app/src/features/service/pages/youtube_partners_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  bool _isCategoriesExpanded = false;

  void _navigateToTab(int tabIndex) {
    ref.read(bottomNavIndexProvider.notifier).state = tabIndex;
    Navigator.pop(context);
  }

  void _pushScreen(Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _openCategoryGrid(
      String title, String type, List<FeedItem> allFeedItems) {
    Navigator.pop(context);

    final filteredItems =
        allFeedItems.where((item) => item.type == type).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenericGridScreen(title: title, items: filteredItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 2. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    final feedAsync = ref.watch(feedContentProvider);
    final List<FeedItem> allItems = feedAsync.valueOrNull ?? [];

    return Drawer(
      backgroundColor: const Color(0xFF0B101D),
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.menu, // Localized "Menu"
                    style: const TextStyle(
                      color: Color(0xFFCFB56C),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            // --- MENU ITEMS ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // --- A. CATEGORIES DROPDOWN ---
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCategoriesExpanded = !_isCategoriesExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFB56C),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.categories, // Localized "Categories"
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            _isCategoriesExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- B. EXPANDED LIST ---
                  if (_isCategoriesExpanded) ...[
                    const SizedBox(height: 12),
                    _buildSubMenuItem(
                      Icons.movie_creation_outlined,
                      l10n.translatedMovies, // Localized
                      () => _openCategoryGrid(
                          l10n.translatedMovies, "MOVIE", allItems),
                    ),
                    _buildSubMenuItem(
                      Icons.tv,
                      l10n.seriesMovies, // Localized
                      () => _openCategoryGrid(
                          l10n.seriesMovies, "SERIES", allItems),
                    ),
                    _buildSubMenuItem(
                      Icons.music_note_outlined,
                      l10n.premiumNesheed, // Localized
                      () => _openCategoryGrid(
                          l10n.premiumNesheed, "MUSIC_VIDEO", allItems),
                    ),
                    _buildSubMenuItem(
                      Icons.menu_book_outlined,
                      l10n.quranTafseer, // Localized
                      () => _pushScreen(const TafsirSheikhsScreen()),
                    ),
                    _buildSubMenuItem(
                      Icons.school_outlined,
                      l10n.prophetHistory, // Localized
                      () => _openCategoryGrid(
                          l10n.prophetHistory, "PROPHET_HISTORY", allItems),
                    ),
                    _buildSubMenuItem(
                      Icons.video_library_outlined,
                      l10n.documentaries, // Localized
                      () => _openCategoryGrid(
                          l10n.documentaries, "DOCUMENTARY", allItems),
                    ),
                    _buildSubMenuItem(
                      Icons.calendar_today_outlined,
                      l10n.alfarukKheber, // Localized
                      () => _pushScreen(const NewsFeedScreen()),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 24),

                  // --- C. MAIN MENU ITEMS ---

                  // 1. Tabs
                  _buildMenuItem(
                    icon: Icons.movie_outlined,
                    label: l10n.yeneMovie, // Localized
                    onTap: () => _navigateToTab(1),
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_month_outlined,
                    label: l10n.khadim, // Localized
                    onTap: () => _navigateToTab(3),
                  ),
                  _buildMenuItem(
                    icon: Icons.menu_book_outlined,
                    label:
                        l10n.iqraReadListen, // Localized "Iqra - Read & Listen"
                    onTap: () => _navigateToTab(4),
                  ),

                  // 2. Content Pages
                  _buildMenuItem(
                    icon: Icons.play_circle_outline,
                    label: l10n.youtubeContent, // Localized
                    onTap: () => _pushScreen(const YoutubePartnersPage()),
                  ),

                  _buildMenuItem(
                    icon: Icons.school_outlined,
                    label: l10n.dawahFree, // Localized
                    onTap: () =>
                        _openCategoryGrid(l10n.dawahFree, "DAWAH", allItems),
                  ),

                  const SizedBox(height: 40),

                  // --- D. SETTINGS ---
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    label: l10n.settings, // Localized
                    onTap: () => _navigateToTab(5),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFCFB56C), size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFCFB56C), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
