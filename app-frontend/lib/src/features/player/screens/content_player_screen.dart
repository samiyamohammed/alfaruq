// lib/src/features/player/screens/content_player_screen.dart

import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/main_scaffold/data/content_details_provider.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ContentPlayerScreen extends ConsumerStatefulWidget {
  final String contentId;
  // Pass related movies here (from Home Page) to show them under the player for Movies
  final List<FeedItem> relatedContent;

  const ContentPlayerScreen({
    super.key,
    required this.contentId,
    this.relatedContent = const [],
  });

  @override
  ConsumerState<ContentPlayerScreen> createState() =>
      _ContentPlayerScreenState();
}

class _ContentPlayerScreenState extends ConsumerState<ContentPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Playlist Management
  List<FeedItem> _playlist = [];
  int _currentIndex = 0;
  bool _isPlayerInitialized = false;
  bool _isSeries = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen awake
  }

  @override
  void dispose() {
    _disposePlayer();
    WakelockPlus.disable();
    // Force portrait when exiting the player screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _disposePlayer() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
  }

  Future<void> _initializePlayer(String videoUrl) async {
    _disposePlayer();
    setState(() => _isPlayerInitialized = false);

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        allowedScreenSleep: false,
        // Disable Chewie's default full screen button if it conflicts with UI
        // allowFullScreen: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Video Error: $errorMessage',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.secondary,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white24,
        ),
      );

      _videoController!.addListener(() {
        if (_videoController!.value.isInitialized &&
            !_videoController!.value.isPlaying &&
            _videoController!.value.position >=
                _videoController!.value.duration) {
          _playNext();
        }
      });

      if (mounted) {
        setState(() => _isPlayerInitialized = true);
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play video: $e')),
        );
      }
    }
  }

  void _playNext() {
    if (_currentIndex < _playlist.length - 1) {
      final nextIndex = _currentIndex + 1;
      final nextItem = _playlist[nextIndex];

      if (nextItem.videoUrl != null) {
        setState(() => _currentIndex = nextIndex);
        _initializePlayer(nextItem.videoUrl!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Up Next: ${nextItem.title}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  void _preparePlaylist(FeedItem rootItem) {
    if (_playlist.isNotEmpty) return;

    if (rootItem.type == 'SERIES') {
      _isSeries = true;
      List<FeedItem> allEpisodes = [];
      if (rootItem.children.isNotEmpty) {
        for (var season in rootItem.children) {
          if (season.children.isNotEmpty) {
            allEpisodes.addAll(season.children);
          }
        }
      }
      _playlist = allEpisodes;
      if (_playlist.isNotEmpty && _playlist[0].videoUrl != null) {
        _initializePlayer(_playlist[0].videoUrl!);
      }
    } else {
      _isSeries = false;
      _playlist = [rootItem];
      if (rootItem.videoUrl != null) {
        _initializePlayer(rootItem.videoUrl!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncContent = ref.watch(contentDetailsProvider(widget.contentId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: asyncContent.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
              child: Text('Error: $err',
                  style: const TextStyle(color: Colors.white))),
          data: (content) {
            if (_playlist.isEmpty) {
              _preparePlaylist(content);
            }

            final List<FeedItem> listItems =
                _isSeries ? _playlist : widget.relatedContent;

            final currentPlayingItem =
                _playlist.isNotEmpty && _currentIndex < _playlist.length
                    ? _playlist[_currentIndex]
                    : content;

            return Column(
              children: [
                // --- 1. VIDEO PLAYER WITH BACK BUTTON ---
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: _isPlayerInitialized && _chewieController != null
                            ? Chewie(controller: _chewieController!)
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text('Loading Stream...',
                                        style: TextStyle(color: Colors.white54))
                                  ],
                                ),
                              ),
                      ),
                    ),
                    // THE NEW BACK BUTTON
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // --- 2. INFO SECTION ---
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[900],
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPlayingItem.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSeries
                            ? '${content.title} - Episode ${_currentIndex + 1}'
                            : 'Movie',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14),
                      ),
                      if (content.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          content.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),

                // --- 3. PLAYLIST / RELATED ---
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: listItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = listItems[index];
                        final isPlaying = _isSeries && index == _currentIndex;

                        return ListTile(
                          onTap: () {
                            if (_isSeries) {
                              if (item.videoUrl != null) {
                                setState(() => _currentIndex = index);
                                _initializePlayer(item.videoUrl!);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No video available for this episode')),
                                );
                              }
                            } else {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ContentPlayerScreen(
                                            contentId: item.id,
                                            relatedContent:
                                                widget.relatedContent,
                                          )));
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          tileColor:
                              isPlaying ? Colors.grey[800] : Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          leading: Container(
                            width: 100,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(4),
                              image: item.thumbnailUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(item.thumbnailUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: item.thumbnailUrl == null
                                ? const Icon(Icons.movie, color: Colors.white24)
                                : null,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isPlaying
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.white,
                              fontWeight:
                                  isPlaying ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _isSeries ? 'Episode ${index + 1}' : 'Movie',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          trailing: isPlaying
                              ? const Icon(Icons.equalizer,
                                  color: Colors.white, size: 20)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
