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

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(feedContentProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(feedContentProvider);
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: feedAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allFeedItems) {
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
                // The Hero Section
                if (featuredItems.isNotEmpty) ...[
                  FeaturedCarousel(items: featuredItems),
                  const SizedBox(height: 40),
                ],

                // 1. Popular Movies Header
                _sectionHeader(l10n.sectionPopularMovies),
                const SizedBox(height: 20),

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

                const SizedBox(height: 24),

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

                const SizedBox(height: 24),

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

                const SizedBox(height: 32),
                TafsirSection(
                  items: const [],
                  onSeeAll: (selectedLanguageId) => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TafsirSheikhsScreen(
                              initialLanguageId: selectedLanguageId))),
                ),
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
                IqraSection(books: books.take(10).toList()),
                if (dawah.isNotEmpty)
                  DawahSection(
                      items: dawah.take(10).toList(),
                      onSeeAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GenericGridScreen(
                                  title: l10n.dawahFree, items: dawah)))),
                const ChannelsSection(),
                const YoutubeSection(),
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
                newsAsync.when(
                    data: (newsList) =>
                        NewsSection(newsList: newsList.take(10).toList()),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink()),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFCFB56C),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFCFB56C).withOpacity(0.5),
                    blurRadius: 8)
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
                color: Color(0xFFCFB56C),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
