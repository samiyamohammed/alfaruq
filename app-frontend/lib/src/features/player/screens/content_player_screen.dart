// lib/src/features/player/screens/content_player_screen.dart

import 'dart:ui'; // For image filter (blur)
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

  List<FeedItem> _playlist = [];
  int _currentIndex = 0;
  bool _isPlayerInitialized = false;
  bool _isSeries = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _disposePlayer();
    WakelockPlus.disable();
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
    if (mounted) setState(() => _isPlayerInitialized = false);

    try {
      debugPrint("🎥 Initializing: $videoUrl");
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio > 0
            ? _videoController!.value.aspectRatio
            : 16 / 9,
        allowedScreenSleep: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(errorMessage, style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFD4AF37), // Gold
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Colors.white24,
        ),
      );

      _videoController!.addListener(() {
        if (_videoController!.value.isInitialized &&
            !_videoController!.value.isPlaying &&
            _videoController!.value.duration > Duration.zero &&
            _videoController!.value.position >=
                _videoController!.value.duration) {
          _playNext();
        }
      });

      if (mounted) setState(() => _isPlayerInitialized = true);
    } catch (e) {
      debugPrint("🛑 Error: $e");
      if (mounted) {
        setState(() => _isPlayerInitialized = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to play: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _playNext() {
    if (_currentIndex < _playlist.length - 1) {
      final nextIndex = _currentIndex + 1;
      final nextItem = _playlist[nextIndex];

      setState(() => _currentIndex = nextIndex);

      // Check if the next item is locked
      if (nextItem.isLocked) {
        _disposePlayer(); // Stop current player so the Lock UI shows up
      } else if (nextItem.videoUrl != null) {
        _initializePlayer(nextItem.videoUrl!);
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
    } else {
      _isSeries = false;
      _playlist = [rootItem];
    }

    // Attempt to play the first item
    if (_playlist.isNotEmpty) {
      final firstItem = _playlist[0];
      // Only play if NOT locked and has URL
      if (!firstItem.isLocked && firstItem.videoUrl != null) {
        _initializePlayer(firstItem.videoUrl!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncContent = ref.watch(contentDetailsProvider(widget.contentId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors derived from theme
    final bgColor = theme.scaffoldBackgroundColor;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final goldColor = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: asyncContent.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (content) {
            if (_playlist.isEmpty) _preparePlaylist(content);

            final listItems = _isSeries ? _playlist : widget.relatedContent;
            final currentItem =
                _playlist.isNotEmpty && _currentIndex < _playlist.length
                    ? _playlist[_currentIndex]
                    : content;

            return Column(
              children: [
                // --- 1. VIDEO PLAYER AREA ---
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        // CHECK IF LOCKED FIRST
                        child: currentItem.isLocked
                            ? _buildLockedScreen(goldColor)
                            : _isPlayerInitialized && _chewieController != null
                                ? Chewie(controller: _chewieController!)
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                      ),
                    ),
                    // Glass-morphism Back Button
                    Positioned(
                      top: 12,
                      left: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // --- 2. INFO & PLAYLIST ---
                Expanded(
                  child: Container(
                    color: bgColor,
                    child: ListView(
                      children: [
                        // A. CURRENTLY PLAYING INFO CARD
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: goldColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: goldColor, width: 1),
                                    ),
                                    child: Text(
                                      currentItem.isLocked
                                          ? "LOCKED"
                                          : "NOW PLAYING",
                                      style: TextStyle(
                                        color: goldColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_isSeries)
                                    Text(
                                      "Episode ${_currentIndex + 1}",
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentItem.title,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              if (content.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  content.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: primaryText.withOpacity(0.7),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // B. SECTION HEADER
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _isSeries ? "All Episodes" : "Related Content",
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // C. LIST OF VIDEOS
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final item = listItems[index];
                            final isPlaying =
                                _isSeries && index == _currentIndex;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? goldColor.withOpacity(0.1)
                                    : surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: isPlaying
                                    ? Border(
                                        left: BorderSide(
                                            color: goldColor, width: 4))
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    if (_isSeries) {
                                      setState(() => _currentIndex = index);
                                      // If locked, dispose player (UI updates to lock screen)
                                      // If not locked, play video
                                      if (item.isLocked) {
                                        _disposePlayer();
                                      } else if (item.videoUrl != null) {
                                        _initializePlayer(item.videoUrl!);
                                      }
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ContentPlayerScreen(
                                            contentId: item.id,
                                            relatedContent:
                                                widget.relatedContent,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        // Thumbnail
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: SizedBox(
                                            width: 80,
                                            height: 50,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                if (item.thumbnailUrl != null)
                                                  Image.network(
                                                      item.thumbnailUrl!,
                                                      fit: BoxFit.cover)
                                                else
                                                  Container(
                                                      color: Colors.grey[800]),
                                                // Overlay icon if playing
                                                if (isPlaying && !item.isLocked)
                                                  Container(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    child: const Icon(
                                                        Icons.equalizer,
                                                        color: Colors.white,
                                                        size: 20),
                                                  ),
                                                // Overlay icon if Locked
                                                if (item.isLocked)
                                                  Container(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    child: const Icon(
                                                      Icons.lock,
                                                      color: Colors.white70,
                                                      size: 20,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Text Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isPlaying
                                                      ? goldColor
                                                      : primaryText,
                                                  fontWeight: isPlaying
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _isSeries
                                                    ? 'Episode ${index + 1}'
                                                    : 'Movie',
                                                style: TextStyle(
                                                  color: primaryText
                                                      .withOpacity(0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isPlaying && !item.isLocked)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Icon(Icons.play_circle_fill,
                                                color: goldColor, size: 24),
                                          ),
                                        if (item.isLocked && !isPlaying)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Icon(Icons.lock_outline,
                                                color: theme.disabledColor,
                                                size: 20),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
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

  // --- UPDATED: Adaptive Locked Screen ---
  Widget _buildLockedScreen(Color goldColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define a threshold for "compact" height (e.g. portrait mode phone)
        final isCompact = constraints.maxHeight < 250;

        return Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          // Use less padding on smaller screens
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: isCompact ? 8 : 24,
          ),
          child: Center(
            child: SingleChildScrollView(
              // Prevents overflow if it still doesn't fit
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 8 : 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 2),
                    ),
                    child: Icon(
                      Icons.lock,
                      color: goldColor,
                      size: isCompact ? 24 : 40,
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 16),
                  Text(
                    "Premium Content",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                  Text(
                    "Locked. Please subscribe to watch.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isCompact ? 12 : 14,
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 24),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Subscription flow not implemented yet."),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 20 : 32,
                        vertical: isCompact ? 8 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      "Unlock Now",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
