import 'dart:async';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ContentPlayerScreen extends ConsumerStatefulWidget {
  final String contentId;
  final List<FeedItem> relatedContent; // Passed from Home (Movies list, Docs list, etc)

  const ContentPlayerScreen({
    super.key,
    required this.contentId,
    this.relatedContent = const [],
  });

  @override
  ConsumerState<ContentPlayerScreen> createState() => _ContentPlayerScreenState();
}

class _ContentPlayerScreenState extends ConsumerState<ContentPlayerScreen> {
  // Controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // State
  bool _isPlayerInitialized = false;
  bool _isSeries = false;
  int _currentEpisodeIndex = 0;
  List<FeedItem> _playlist = [];
  
  // To track the item currently being displayed/played
  late String _currentContentId;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen on
    _currentContentId = widget.contentId;
  }

  @override
  void dispose() {
    _disposePlayer();
    WakelockPlus.disable();
    // Force portrait when exiting
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
            child: Text(errorMessage, style: const TextStyle(color: Colors.white)),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFCFB56C), // Gold
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Colors.white24,
        ),
      );

      // Listener for Auto-Play Next (Only for Series)
      _videoController!.addListener(() {
        if (_isSeries && 
            _videoController!.value.isInitialized && 
            !_videoController!.value.isPlaying && 
            _videoController!.value.position >= _videoController!.value.duration) {
          _playNextEpisode();
        }
      });

      if (mounted) setState(() => _isPlayerInitialized = true);
    } catch (e) {
      debugPrint("Player Error: $e");
      if (mounted) setState(() => _isPlayerInitialized = false);
    }
  }

  void _playNextEpisode() {
    if (_currentEpisodeIndex < _playlist.length - 1) {
      final nextIndex = _currentEpisodeIndex + 1;
      final nextEpisode = _playlist[nextIndex];

      setState(() => _currentEpisodeIndex = nextIndex);

      if (nextEpisode.isLocked) {
        _disposePlayer(); // Show Lock Screen
      } else if (nextEpisode.videoUrl != null) {
        _initializePlayer(nextEpisode.videoUrl!);
      }
    }
  }

  void _setupContent(FeedItem item) {
    // Determine if this is a Series or Single Video
    if (item.type == 'SERIES' && item.children.isNotEmpty) {
      _isSeries = true;
      _playlist = item.children; // Episodes
      
      // Try to play first available episode
      if (_playlist.isNotEmpty && !_playlist[0].isLocked && _playlist[0].videoUrl != null) {
        if (!_isPlayerInitialized) _initializePlayer(_playlist[0].videoUrl!);
      }
    } else {
      _isSeries = false;
      _playlist = [item]; // Single Item Playlist
      
      if (!item.isLocked && item.videoUrl != null) {
        if (!_isPlayerInitialized) _initializePlayer(item.videoUrl!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch details using the ID (Handling fresh data)
    final contentAsync = ref.watch(feedDetailsProvider(_currentContentId));

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      body: SafeArea(
        child: contentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
          error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
          data: (content) {
            // Initialize Playlist Logic only once per content load
            if (_playlist.isEmpty || _playlist.first.parentId != content.id && content.type == 'SERIES') {
               _setupContent(content);
            } else if (!_isSeries && _playlist.isEmpty) {
               _setupContent(content);
            }

            final currentItem = _isSeries 
                ? _playlist[_currentEpisodeIndex] 
                : content;

            return Column(
              children: [
                // --- 1. PLAYER AREA ---
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (currentItem.isLocked)
                          _buildLockedUI()
                        else if (_isPlayerInitialized && _chewieController != null)
                          Chewie(controller: _chewieController!)
                        else
                          const CircularProgressIndicator(color: Color(0xFFCFB56C)),

                        // Back Button Overlay
                        Positioned(
                          top: 10, left: 10,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- 2. INFO & RELATED CONTENT ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Title & Series Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                if (_isSeries)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Playing: ${currentItem.title}",
                                      style: const TextStyle(color: Color(0xFFCFB56C), fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        content.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),

                      const Divider(color: Colors.white12, height: 32),

                      // --- 3. DYNAMIC LIST (Episodes or Related) ---
                      Text(
                        _isSeries ? "Episodes" : "Related ${content.type == 'DOCUMENTARY' ? 'Documentaries' : 'Movies'}",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (_isSeries)
                        _buildEpisodesList()
                      else
                        _buildRelatedList(content.id), // Exclude current ID
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildEpisodesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _playlist.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final episode = _playlist[index];
        final isPlaying = index == _currentEpisodeIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentEpisodeIndex = index;
              _isPlayerInitialized = false;
            });
            _disposePlayer();
            if (!episode.isLocked && episode.videoUrl != null) {
              _initializePlayer(episode.videoUrl!);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPlaying ? const Color(0xFFCFB56C).withOpacity(0.1) : const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPlaying ? const Color(0xFFCFB56C) : Colors.transparent
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPlaying ? Icons.play_circle_fill : (episode.isLocked ? Icons.lock : Icons.play_circle_outline),
                  color: isPlaying ? const Color(0xFFCFB56C) : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    episode.title,
                    style: TextStyle(
                      color: isPlaying ? const Color(0xFFCFB56C) : Colors.white,
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(episode.duration),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelatedList(String currentId) {
    // Filter out the current video from the related list passed from Home
    final related = widget.relatedContent.where((i) => i.id != currentId).toList();

    if (related.isEmpty) {
      return const Text("No related content found.", style: TextStyle(color: Colors.white38));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: related.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = related[index];
        return GestureDetector(
          onTap: () {
            // RELOAD SCREEN WITH NEW CONTENT
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ContentPlayerScreen(
                  contentId: item.id,
                  relatedContent: widget.relatedContent, // Pass the same list
                ),
              ),
            );
          },
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.thumbnailUrl ?? '',
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 120, height: 68, color: Colors.grey[900]),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.isLocked) ...[
                          const Icon(Icons.lock, color: Color(0xFFCFB56C), size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          item.type,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFFCFB56C), size: 50),
          const SizedBox(height: 16),
          const Text(
            "Premium Content",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Subscribe to unlock this video",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subscription Flow")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFB56C),
              foregroundColor: Colors.black,
            ),
            child: const Text("Unlock Now"),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return "";
    final d = Duration(seconds: seconds);
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}