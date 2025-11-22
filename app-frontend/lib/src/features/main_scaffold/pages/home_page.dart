// lib/src/features/main_scaffold/pages/home_page.dart
import 'package:al_faruk_app/src/core/models/content_item_model.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/content_carousel.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/hero_banner.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // --- Mock Data ---
  // In a real app, this data would come from an API.
  static const _featuredContent = ContentItem(
    id: '1',
    title: 'The Beauty of Islamic Art',
    thumbnailUrl: 'assets/images/thumb_islamic_art.png',
  );

  static const _newTrailers = [
    ContentItem(
        id: '2',
        title: 'The Golden Age',
        thumbnailUrl: 'assets/images/thumb_baghdad.png'),
    ContentItem(
        id: '3',
        title: 'Art of Calligraphy',
        thumbnailUrl: 'assets/images/thumb_calligraphy.png'),
    ContentItem(
        id: '1',
        title: 'Islamic Art',
        thumbnailUrl: 'assets/images/thumb_islamic_art.png'),
  ];

  static const _popularMovies = [
    ContentItem(
        id: '3',
        title: 'Art of Calligraphy',
        thumbnailUrl: 'assets/images/thumb_calligraphy.png'),
    ContentItem(
        id: '1',
        title: 'Islamic Art',
        thumbnailUrl: 'assets/images/thumb_islamic_art.png'),
    ContentItem(
        id: '2',
        title: 'The Golden Age',
        thumbnailUrl: 'assets/images/thumb_baghdad.png'),
  ];
  // --- End Mock Data ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          // The large banner at the top
          HeroBanner(content: _featuredContent),

          // The first horizontally scrolling list
          ContentCarousel(
            title: 'New Trailers',
            items: _newTrailers,
          ),

          SizedBox(height: 16), // Spacer

          // The second horizontally scrolling list
          ContentCarousel(
            title: 'Popular Movies',
            items: _popularMovies,
          ),

          SizedBox(height: 24), // Spacer at the bottom
        ],
      ),
    );
  }
}
