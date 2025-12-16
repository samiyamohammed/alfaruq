import 'package:al_faruk_app/src/core/models/youtube_video_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart'; // Import for provider
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

// 1. Change to ConsumerStatefulWidget to access Providers
class YoutubeContentPlayer extends ConsumerStatefulWidget {
  final YoutubeVideo video;
  const YoutubeContentPlayer({super.key, required this.video});

  @override
  ConsumerState<YoutubeContentPlayer> createState() =>
      _YoutubeContentPlayerState();
}

class _YoutubeContentPlayerState extends ConsumerState<YoutubeContentPlayer> {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // 2. Local State for the currently playing video
  late YoutubeVideo _currentVideo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with the video passed from the previous screen
    _currentVideo = widget.video;
    _initializePlayer();
  }

  @override
  void dispose() {
    _disposeControllers();
    _yt.close();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
  }

  // 3. Logic to switch video when an item in the list is clicked
  Future<void> _playVideo(YoutubeVideo newVideo) async {
    setState(() {
      _currentVideo = newVideo;
      _isLoading = true;
      _errorMessage = null;
    });

    // Dispose old controllers before initializing new ones
    _disposeControllers();

    await _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      var manifest =
          await _yt.videos.streamsClient.getManifest(_currentVideo.videoId);
      var streamInfo = manifest.muxed.withHighestBitrate();

      _videoController = VideoPlayerController.networkUrl(streamInfo.url);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        allowedScreenSleep: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFCFB56C),
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Colors.white24,
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to play video. Restricted or Network issue.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. Watch the provider to get the list of "Up Next" videos
    final youtubeAsync = ref.watch(youtubeContentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Now Playing", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // --- PLAYER AREA ---
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFCFB56C)))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 40),
                              const SizedBox(height: 8),
                              Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        )
                      : Chewie(controller: _chewieController!),
            ),
          ),

          // --- SCROLLABLE CONTENT AREA ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Current Video Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentVideo.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white10,
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentVideo.channelTitle,
                                style: const TextStyle(
                                  color: Color(0xFFCFB56C),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Expandable Description (Simple version)
                        Text(
                          _currentVideo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white12, thickness: 1),

                  // 2. Up Next Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Up Next",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 3. Up Next List
                  youtubeAsync.when(
                    loading: () => const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child:
                          CircularProgressIndicator(color: Color(0xFFCFB56C)),
                    )),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (videos) {
                      // Filter out the currently playing video
                      final upNextVideos = videos
                          .where((v) => v.videoId != _currentVideo.videoId)
                          .toList();

                      return ListView.separated(
                        shrinkWrap:
                            true, // Important inside SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // Disable internal scrolling
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: upNextVideos.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final video = upNextVideos[index];
                          return GestureDetector(
                            onTap: () => _playVideo(video), // Switch video
                            child: Container(
                              color: Colors.transparent, // Hit test
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      video.thumbnailUrl,
                                      width: 120,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                          width: 120,
                                          height: 68,
                                          color: Colors.grey[900]),
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
                                          video.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          video.channelTitle,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
