import 'package:al_faruk_app/src/core/models/content_item_model.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart'; // Import Provider
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/content_carousel.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/hero_banner.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsyncValue = ref.watch(feedContentProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: feedAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
        data: (feedItems) {
          if (feedItems.isEmpty) {
            return Center(child: Text(l10n.noContent));
          }

          final movies =
              feedItems.where((item) => item.type == 'MOVIE').toList();
          final series =
              feedItems.where((item) => item.type == 'SERIES').toList();
          final musicVideos =
              feedItems.where((item) => item.type == 'MUSIC_VIDEO').toList();

          void sortItems(List<FeedItem> items) {
            if (items.isNotEmpty) {
              items.sort((a, b) {
                final dateA = a.createdAt ?? DateTime(0);
                final dateB = b.createdAt ?? DateTime(0);
                return dateB.compareTo(dateA);
              });
            }
          }

          sortItems(movies);
          sortItems(series);
          sortItems(musicVideos);

          final featuredMovie = movies.isNotEmpty ? movies.first : null;

          List<ContentItem> mapToContentItems(List<FeedItem> items) {
            return items.map((item) {
              return ContentItem(
                id: item.id,
                title: item.title,
                thumbnailUrl: item.thumbnailUrl ?? '',
                isLocked: item.isLocked,
              );
            }).toList();
          }

          final trailerItems = mapToContentItems(
              feedItems.where((item) => item.trailerUrl != null).toList());
          final movieItems = mapToContentItems(movies);
          final seriesItems = mapToContentItems(series);
          final musicVideoItems = mapToContentItems(musicVideos);

          return ListView(
            children: [
              // 1. HERO BANNER
              if (featuredMovie != null)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ContentPlayerScreen(
                        contentId: featuredMovie.id,
                        relatedContent: movies,
                      ),
                    ));
                  },
                  child: HeroBanner(
                    content: ContentItem(
                      id: featuredMovie.id,
                      title: featuredMovie.title,
                      thumbnailUrl: featuredMovie.thumbnailUrl ?? '',
                      isLocked: featuredMovie.isLocked,
                    ),
                  ),
                )
              else
                const SizedBox(height: 24),

              // 2. TRAILERS SECTION
              if (trailerItems.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  title: l10n.sectionTrailers,
                  onSeeAll: () {
                    // Switch to Library Page (Index 2) -> Trailers Tab (Index 2)
                    ref.read(libraryTabIndexProvider.notifier).state = 2;
                    ref.read(bottomNavIndexProvider.notifier).state = 2;
                  },
                ),
                ContentCarousel(
                  items: trailerItems,
                  title: '',
                  onItemTap: (contentItem) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ContentPlayerScreen(
                        contentId: contentItem.id,
                        relatedContent: movies,
                      ),
                    ));
                  },
                ),
              ],

              const SizedBox(height: 8),

              // 3. POPULAR MOVIES SECTION
              if (movieItems.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  title: l10n.sectionPopularMovies,
                  onSeeAll: () {
                    // Switch to Library Page (Index 2) -> Movies Tab (Index 0)
                    ref.read(libraryTabIndexProvider.notifier).state = 0;
                    ref.read(bottomNavIndexProvider.notifier).state = 2;
                  },
                ),
                ContentCarousel(
                  items: movieItems,
                  title: '',
                  onItemTap: (contentItem) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ContentPlayerScreen(
                        contentId: contentItem.id,
                        relatedContent: movies,
                      ),
                    ));
                  },
                ),
              ],

              const SizedBox(height: 8),

              // 4. MUSIC VIDEOS SECTION
              if (musicVideoItems.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  title: l10n.sectionMusicVideos,
                  onSeeAll: () {
                    // Switch to Videos Page (Index 1) -> Music Tab (Index 1)
                    ref.read(videosTabIndexProvider.notifier).state = 1;
                    ref.read(bottomNavIndexProvider.notifier).state = 1;
                  },
                ),
                ContentCarousel(
                  items: musicVideoItems,
                  title: '',
                  onItemTap: (contentItem) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ContentPlayerScreen(
                        contentId: contentItem.id,
                        relatedContent: musicVideos,
                      ),
                    ));
                  },
                ),
              ],

              const SizedBox(height: 8),

              // 5. SERIES SECTION
              if (seriesItems.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  title: l10n.sectionSeries,
                  onSeeAll: () {
                    // Switch to Library Page (Index 2) -> Series Tab (Index 1)
                    ref.read(libraryTabIndexProvider.notifier).state = 1;
                    ref.read(bottomNavIndexProvider.notifier).state = 2;
                  },
                ),
                ContentCarousel(
                  items: seriesItems,
                  title: '',
                  onItemTap: (contentItem) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ContentPlayerScreen(
                        contentId: contentItem.id,
                        relatedContent: series,
                      ),
                    ));
                  },
                ),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onSeeAll,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                l10n.seeAll,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
