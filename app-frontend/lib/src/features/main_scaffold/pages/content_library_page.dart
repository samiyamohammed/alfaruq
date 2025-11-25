import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';

class ContentLibraryPage extends ConsumerStatefulWidget {
  const ContentLibraryPage({super.key});

  @override
  ConsumerState<ContentLibraryPage> createState() => _ContentLibraryPageState();
}

class _ContentLibraryPageState extends ConsumerState<ContentLibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsyncValue = ref.watch(feedContentProvider);
    final l10n = AppLocalizations.of(context)!;

    // LISTEN TO PROVIDER: When Home Page changes the tab, animate to it.
    ref.listen(libraryTabIndexProvider, (previous, next) {
      _tabController.animateTo(next);
    });

    return Scaffold(
      appBar: AppBar(
        // Hide Title area, show only Tabs
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.secondary,
          unselectedLabelColor: Colors.grey,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: l10n.tabMovies),
            Tab(text: l10n.tabSeries),
            Tab(text: l10n.tabTrailers),
          ],
        ),
      ),
      body: feedAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
        data: (feedItems) {
          final movies =
              feedItems.where((item) => item.type == 'MOVIE').toList();
          _sortItems(movies);

          final series =
              feedItems.where((item) => item.type == 'SERIES').toList();
          _sortItems(series);

          final trailers =
              feedItems.where((item) => item.trailerUrl != null).toList();
          _sortItems(trailers);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGrid(movies,
                  allContextItems: movies, noContentText: l10n.noContentFound),
              _buildGrid(series,
                  allContextItems: series, noContentText: l10n.noContentFound),
              _buildGrid(trailers,
                  allContextItems: movies,
                  isTrailer: true,
                  noContentText: l10n.noContentFound),
            ],
          );
        },
      ),
    );
  }

  void _sortItems(List<FeedItem> items) {
    if (items.isNotEmpty) {
      items.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(0);
        final dateB = b.createdAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
    }
  }

  Widget _buildGrid(List<FeedItem> items,
      {required List<FeedItem> allContextItems,
      bool isTrailer = false,
      required String noContentText}) {
    if (items.isEmpty) {
      return Center(child: Text(noContentText));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ContentPlayerScreen(
                  contentId: item.id,
                  relatedContent: allContextItems,
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
                    color: Colors.grey[900],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child:
                                      Icon(Icons.movie, color: Colors.white54)),
                        ),
                      ),
                      Center(
                        child: Icon(
                          isTrailer
                              ? Icons.play_circle_outline
                              : Icons.play_circle_fill,
                          color: Colors.white.withOpacity(0.8),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
