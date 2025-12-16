import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class ProphetHistoryScreen extends ConsumerWidget {
  final String contentId;

  const ProphetHistoryScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(feedDetailsProvider(contentId));

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D), // Deep Blue Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCFB56C), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: detailsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.white))),
        data: (item) {
          final episodes = item.children;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section (Image + Overlay Card)
                SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      // Background Image
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(item.thumbnailUrl ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.1),
                                const Color(0xFF0B101D)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Info Card
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151E32),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFCFB56C), width: 1),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Placeholder Arabic (Dynamic if backend provides it)
                              const Text(
                                "عليه السلام",
                                style: TextStyle(
                                    color: Color(0xFFCFB56C),
                                    fontSize: 16,
                                    fontFamily: 'serif'),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.mosque,
                                      color: Colors.white54, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.tags?.split(',').first ?? "History",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                          width: 4, height: 24, color: const Color(0xFFCFB56C)),
                      const SizedBox(width: 8),
                      const Text(
                        "Related Videos & Topics",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Episodes List
                if (episodes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No episodes available.",
                        style: TextStyle(color: Colors.white54)),
                  )
                else
                  ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: episodes.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _AudioEpisodeTile(episode: episodes[index]);
                    },
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Separate Widget for Audio Tile to manage VideoPlayerController state
class _AudioEpisodeTile extends StatefulWidget {
  final FeedItem episode;
  const _AudioEpisodeTile({required this.episode});

  @override
  State<_AudioEpisodeTile> createState() => _AudioEpisodeTileState();
}

class _AudioEpisodeTileState extends State<_AudioEpisodeTile> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_controller == null) {
      if (widget.episode.audioUrl == null) return;

      setState(() => _isInitialized = false); // Show loader

      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.episode.audioUrl!));
      await _controller!.initialize();

      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });

      setState(() => _isInitialized = true);
    }

    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Play Button
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCFB56C),
                      shape: BoxShape.circle,
                    ),
                    child: (!_isInitialized && _controller != null)
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volume_up,
                              color: Color(0xFFCFB56C), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.episode.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Progress Bar (Simple)
                      if (_isInitialized)
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFFCFB56C),
                            backgroundColor: Colors.white10,
                            bufferedColor: Colors.white24,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: 0,
                            backgroundColor: Colors.white10,
                            color: const Color(0xFFCFB56C).withOpacity(0.3),
                          ),
                        ),

                      // Duration Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_isInitialized)
                            ValueListenableBuilder(
                              valueListenable: _controller!,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                return Text(
                                  _formatDuration(value.position),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                );
                              },
                            )
                          else
                            const Text("0:00",
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                          Text(
                            _formatDuration(Duration(
                                seconds: widget.episode.duration ?? 0)),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description Footer
          if (widget.episode.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1525), // Darker shade
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text(
                widget.episode.description,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
