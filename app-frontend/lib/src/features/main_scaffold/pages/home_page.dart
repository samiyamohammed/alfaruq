import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/generic_grid_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/channels_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/dawah_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/featured_carousel.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/horizontal_content_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/iqra_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/news_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/tafsir_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/youtube_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/tafsir_sheikhs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

// 1. Add WidgetsBindingObserver to listen to App Lifecycle
class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 2. Register this class as an observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 3. Remove observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. Listen for when the app comes to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user just came back to the app (e.g., from Chapa or another screen)
      // We force a refresh of the feed so 'isLocked' updates to false
      print("🔄 App Resumed: Refreshing Home Feed...");
      ref.invalidate(feedContentProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(feedContentProvider);
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      body: feedAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allFeedItems) {
          // --- FILTERING DATA ---
          final movies = allFeedItems.where((i) => i.type == 'MOVIE').toList();
          final series = allFeedItems.where((i) => i.type == 'SERIES').toList();
          final prophets =
              allFeedItems.where((i) => i.type == 'PROPHET_HISTORY').toList();
          final dawah = allFeedItems.where((i) => i.type == 'DAWAH').toList();
          final docs =
              allFeedItems.where((i) => i.type == 'DOCUMENTARY').toList();
          final menzumas =
              allFeedItems.where((i) => i.type == 'MUSIC_VIDEO').toList();
          final books = allFeedItems.where((i) => i.type == 'BOOK').toList();

          final featuredItems = movies.take(5).toList();

          return RefreshIndicator(
            color: const Color(0xFFCFB56C),
            onRefresh: () async => ref.refresh(feedContentProvider),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 100),

                // 1. Featured Movies
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    l10n.sectionPopularMovies,
                    style: const TextStyle(
                      color: Color(0xFFCFB56C),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (featuredItems.isNotEmpty)
                  FeaturedCarousel(items: featuredItems),

                const SizedBox(height: 24),

                // 2. Translated Films
                if (movies.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.translatedMovies,
                    items: movies.take(10).toList(),
                    isPortrait: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.translatedMovies, items: movies))),
                  ),

                const SizedBox(height: 12),

                // 3. Series Films
                if (series.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.seriesMovies,
                    items: series.take(10).toList(),
                    isPortrait: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.seriesMovies, items: series))),
                  ),

                const SizedBox(height: 12),

                // 4. Premium Menzumas
                if (menzumas.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.premiumNesheed,
                    items: menzumas.take(10).toList(),
                    isPortrait: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.premiumNesheed, items: menzumas))),
                  ),

                const SizedBox(height: 12),

                // 5. Quran Tafsir
                TafsirSection(
                  items: const [],
                  onSeeAll: (selectedLanguageId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TafsirSheikhsScreen(
                          initialLanguageId: selectedLanguageId,
                        ),
                      ),
                    );
                  },
                ),

                // 6. Prophets History
                if (prophets.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.prophetHistory,
                    items: prophets.take(10).toList(),
                    isLandscape: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.prophetHistory, items: prophets))),
                  ),

                // 7. Iqra Section
                IqraSection(books: books.take(10).toList()),

                // 8. Da'wah
                if (dawah.isNotEmpty)
                  DawahSection(
                    items: dawah.take(10).toList(),
                    onSeeAll: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GenericGridScreen(
                                  title: l10n.dawahFree, items: dawah)));
                    },
                  ),

                // 9. Our Channels
                const ChannelsSection(),

                // 10. Popular on YouTube
                const YoutubeSection(),

                // 11. Documentaries
                if (docs.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.documentaries,
                    items: docs.take(10).toList(),
                    isLandscape: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.documentaries, items: docs))),
                  ),

                // 12. Alfaruk Kheber
                newsAsync.when(
                  data: (newsList) =>
                      NewsSection(newsList: newsList.take(10).toList()),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}
