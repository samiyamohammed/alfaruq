// lib/src/features/main_scaffold/pages/home_page.dart

// 1. IMPORT NECESSARY MODELS, PROVIDERS, AND WIDGETS
import 'package:al_faruk_app/src/core/models/content_item_model.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/content_carousel.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/hero_banner.dart';
import 'package:flutter/material.dart';
// 2. IMPORT RIVERPOD
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. CONVERT TO A ConsumerWidget
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 4. WATCH THE NEW feedContentProvider
    final feedAsyncValue = ref.watch(feedContentProvider);

    return Scaffold(
      // 5. USE .when() TO HANDLE LOADING, ERROR, AND DATA STATES
      body: feedAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (feedItems) {
          // --- DATA PROCESSING ---
          if (feedItems.isEmpty) {
            return const Center(child: Text('No content available.'));
          }

          // Filter for movies and series
          final movies =
              feedItems.where((item) => item.type == 'MOVIE').toList();
          final series =
              feedItems.where((item) => item.type == 'SERIES').toList();

          // Find the newest movie for the Hero Banner
          // Sort by createdAt date in descending order and take the first one.
          FeedItem? featuredMovie;
          if (movies.isNotEmpty) {
            movies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            featuredMovie = movies.first;
          }

          // Create lists of ContentItem for the carousels
          // This adapts our detailed FeedItem model to the generic ContentCarousel widget
          final trailerItems = feedItems
              .where((item) => item.trailerUrl != null)
              .map((item) => ContentItem(
                  id: item.id,
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl))
              .toList();

          final movieItems = movies
              .map((item) => ContentItem(
                  id: item.id,
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl))
              .toList();

          final seriesItems = series
              .map((item) => ContentItem(
                  id: item.id,
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl))
              .toList();

          // --- UI BUILD ---
          return ListView(
            children: [
              // Use the newest movie for the Hero Banner, with a fallback
              if (featuredMovie != null)
                HeroBanner(
                  content: ContentItem(
                    id: featuredMovie.id,
                    title: featuredMovie.title,
                    thumbnailUrl: featuredMovie.thumbnailUrl,
                  ),
                )
              else
                const SizedBox(
                    height: 24), // Show a spacer if no movies are found

              // Carousel for New Trailers
              if (trailerItems.isNotEmpty)
                ContentCarousel(
                  title: 'New Trailers',
                  items: trailerItems,
                ),

              const SizedBox(height: 16),

              // Carousel for Popular Movies
              if (movieItems.isNotEmpty)
                ContentCarousel(
                  title: 'Popular Movies',
                  items: movieItems,
                ),

              const SizedBox(height: 16),

              // NEW Carousel for Series
              if (seriesItems.isNotEmpty)
                ContentCarousel(
                  title: 'Series',
                  items: seriesItems,
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
