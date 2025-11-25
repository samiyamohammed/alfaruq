import 'package:al_faruk_app/src/core/models/video_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/video_player/screens/video_player_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';

class VideosPage extends ConsumerStatefulWidget {
  const VideosPage({super.key});

  @override
  ConsumerState<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends ConsumerState<VideosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isYoutubeLoading = true;
  String? _youtubeError;
  List<Video> _allYoutubeVideos = [];
  List<Video> _filteredYoutubeVideos = [];
  final TextEditingController _searchController = TextEditingController();
  final String _playlistId = 'UUDIi_4EqI8j8e8rAyIIoPsQ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchYoutubeVideos();
    });

    _searchController.addListener(_filterYoutubeVideos);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_filterYoutubeVideos);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchYoutubeVideos() async {
    try {
      final youTubeService = ref.read(youtubeServiceProvider);
      final videos =
          await youTubeService.fetchPlaylistVideos(playlistId: _playlistId);

      if (mounted) {
        setState(() {
          _allYoutubeVideos = videos;
          _filteredYoutubeVideos = videos;
          _isYoutubeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _youtubeError = e.toString();
          _isYoutubeLoading = false;
        });
      }
    }
  }

  void _filterYoutubeVideos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredYoutubeVideos = _allYoutubeVideos.where((video) {
        return video.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // LISTEN TO PROVIDER: When Home Page changes the tab, animate to it.
    ref.listen(videosTabIndexProvider, (previous, next) {
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
            Tab(text: l10n.tabPlaylists),
            Tab(text: l10n.tabMusicVideos),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Playlists
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchPlaylists,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(child: _buildYoutubeContent(l10n)),
            ],
          ),
          // Tab 2: Music Videos
          _buildMusicVideoContent(l10n),
        ],
      ),
    );
  }

  Widget _buildYoutubeContent(AppLocalizations l10n) {
    if (_isYoutubeLoading)
      return const Center(child: CircularProgressIndicator());

    if (_youtubeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('$_youtubeError'),
        ),
      );
    }

    if (_filteredYoutubeVideos.isEmpty) {
      return Center(child: Text(l10n.noVideosFound));
    }

    return ListView.builder(
      itemCount: _filteredYoutubeVideos.length,
      itemBuilder: (context, index) {
        final video = _filteredYoutubeVideos[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                video: video,
                playlist: _allYoutubeVideos,
              ),
            ));
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.channelName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMusicVideoContent(AppLocalizations l10n) {
    final feedAsyncValue = ref.watch(feedContentProvider);

    return feedAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
      data: (feedItems) {
        final musicVideos =
            feedItems.where((item) => item.type == 'MUSIC_VIDEO').toList();

        if (musicVideos.isNotEmpty) {
          musicVideos.sort((a, b) {
            final dateA = a.createdAt ?? DateTime(0);
            final dateB = b.createdAt ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
        }

        if (musicVideos.isEmpty) {
          return Center(child: Text(l10n.noVideosFound));
        }

        return ListView.builder(
          itemCount: musicVideos.length,
          itemBuilder: (context, index) {
            final item = musicVideos[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ContentPlayerScreen(
                    contentId: item.id,
                    relatedContent: musicVideos,
                  ),
                ));
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          item.thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 200,
                            color: Colors.grey[900],
                            child: const Center(
                                child: Icon(Icons.music_note,
                                    color: Colors.white24)),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.tabMusicVideos,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
