// lib/src/features/main_scaffold/pages/videos_page.dart
import 'package:al_faruk_app/src/core/models/video_model.dart';
// 1. IMPORT RIVERPOD AND THE NEW PROVIDER
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/video_player/screens/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 2. CONVERT TO ConsumerStatefulWidget
class VideosPage extends ConsumerStatefulWidget {
  const VideosPage({super.key});

  @override
  // 3. UPDATE THE createState SIGNATURE
  ConsumerState<VideosPage> createState() => _VideosPageState();
}

// 4. CHANGE State TO ConsumerState
class _VideosPageState extends ConsumerState<VideosPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Video> _allVideos = [];
  List<Video> _filteredVideos = [];

  final TextEditingController _searchController = TextEditingController();

  // The playlist ID is kept but no longer essential for the current API endpoint
  final String _playlistId = 'UUDIi_4EqI8j8e8rAyIIoPsQ';

  @override
  void initState() {
    super.initState();
    // Use this pattern to call async code safely from initState in a ConsumerWidget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVideos();
    });

    _searchController.addListener(_filterVideos);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterVideos);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideos() async {
    try {
      // 5. READ THE YOUTUBE SERVICE FROM THE RIVERPOD PROVIDER
      // This ensures we get the service with the authenticated Dio client.
      final youTubeService = ref.read(youtubeServiceProvider);
      final videos =
          await youTubeService.fetchPlaylistVideos(playlistId: _playlistId);

      // Check if the widget is still mounted before updating the state
      if (mounted) {
        setState(() {
          _allVideos = videos;
          _filteredVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterVideos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVideos = _allVideos.where((video) {
        return video.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  // The rest of the file (build method and UI) remains unchanged
  // as it was already well-structured to handle different states.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search playlists...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
              '$_errorMessage'), // The error message will now come from the service
        ),
      );
    }

    if (_filteredVideos.isEmpty) {
      return const Center(child: Text('No videos found.'));
    }

    return ListView.builder(
      itemCount: _filteredVideos.length,
      itemBuilder: (context, index) {
        final video = _filteredVideos[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                video: video,
                playlist: _allVideos,
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.error_outline, color: Colors.red)),
                    );
                  },
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
}
