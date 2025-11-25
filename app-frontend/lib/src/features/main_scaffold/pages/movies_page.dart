import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart'; // Import Player
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoviesPage extends ConsumerWidget {
  const MoviesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsyncValue = ref.watch(feedContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies Library'),
      ),
      body: feedAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (feedItems) {
          final movies =
              feedItems.where((item) => item.type == 'MOVIE').toList();

          if (movies.isEmpty) {
            return const Center(child: Text('No movies available.'));
          }

          // FIX: Safe Sorting
          movies.sort((a, b) {
            final dateA = a.createdAt ?? DateTime(0);
            final dateB = b.createdAt ?? DateTime(0);
            return dateB.compareTo(dateA);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return _buildMovieCard(context, movie, movies);
            },
          );
        },
      ),
    );
  }

  Widget _buildMovieCard(
      BuildContext context, FeedItem movie, List<FeedItem> allMovies) {
    return InkWell(
      onTap: () {
        // Navigate to the new Player Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ContentPlayerScreen(
              contentId: movie.id,
              relatedContent: allMovies, // Pass list for "Up Next"
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  movie.thumbnailUrl ?? '', // FIX: Handle null URL
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.movie, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
