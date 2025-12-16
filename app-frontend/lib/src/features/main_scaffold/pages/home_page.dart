import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    final feedAsync = ref.watch(feedContentProvider);
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
            onRefresh: () async => ref.refresh(feedContentProvider),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 100),

                // 1. Featured Movies
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    l10n.sectionPopularMovies, // Localized
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
                    title: l10n.translatedMovies, // Localized
                    items: movies.take(10).toList(),
                    isPortrait: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.translatedMovies, // Localized
                                items: movies))),
                  ),

                const SizedBox(height: 12),

                // 3. Series Films
                if (series.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.seriesMovies, // Localized
                    items: series.take(10).toList(),
                    isPortrait: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.seriesMovies, // Localized
                                items: series))),
                  ),

                const SizedBox(height: 12),

                // 4. Premium Menzumas
                if (menzumas.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.premiumNesheed, // Localized
                    items: menzumas.take(10).toList(),
                    isPortrait: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.premiumNesheed, // Localized
                                items: menzumas))),
                  ),

                const SizedBox(height: 12),

                // 5. Quran Tafsir
                TafsirSection(
                  items: const [],
                  // UPDATED CALLBACK: Accepts the ID
                  onSeeAll: (selectedLanguageId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TafsirSheikhsScreen(
                          // This requires the TafsirSheikhsScreen file to be updated first
                          initialLanguageId: selectedLanguageId,
                        ),
                      ),
                    );
                  },
                ),

                // 6. Prophets History
                if (prophets.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.prophetHistory, // Localized
                    items: prophets.take(10).toList(),
                    isLandscape: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.prophetHistory, // Localized
                                items: prophets))),
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
                                  title: l10n.dawahFree, // Localized
                                  items: dawah)));
                    },
                  ),

                // 9. Our Channels
                const ChannelsSection(),

                // 10. Popular on YouTube
                const YoutubeSection(),

                // 11. Documentaries
                if (docs.isNotEmpty)
                  HorizontalContentSection(
                    title: l10n.documentaries, // Localized
                    items: docs.take(10).toList(),
                    isLandscape: true,
                    onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GenericGridScreen(
                                title: l10n.documentaries, // Localized
                                items: docs))),
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
