import 'package:al_faruk_app/src/core/models/video_model.dart';
import 'package:al_faruk_app/src/features/video_player/widgets/related_videos_list.dart';
import 'package:al_faruk_app/src/features/video_player/widgets/video_description_widget.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  final List<Video> playlist;
  const VideoPlayerScreen(
      {super.key, required this.video, required this.playlist});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  late Video _currentVideo;

  // Changed default state to false because we haven't started loading yet
  bool _isLoading = false;
  bool _isPlayerReady = false;
  String? _errorMessage;

  final _yt = yt.YoutubeExplode();

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    // REMOVED: _initializePlayer(_currentVideo.id);
    // We wait for the user to click play now.
  }

  Future<void> _initializePlayer(String videoId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _disposeControllers();

    try {
      final String videoUrl = 'https://www.youtube.com/watch?v=$videoId';

      var manifest = await _yt.videos.streamsClient.getManifest(videoUrl);
      var streamInfo = manifest.muxed.withHighestBitrate();

      _videoController = VideoPlayerController.networkUrl(streamInfo.url);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFD4AF37),
          handleColor: Colors.white,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white24,
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlayerReady = true; // Mark player as ready
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Unable to play video.\nIt might be restricted or deleted.";
        });
        debugPrint("YouTube Playback Error: $e");
      }
    }
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
    _isPlayerReady = false;
  }

  void _playNextVideo(Video nextVideo) {
    setState(() {
      _currentVideo = nextVideo;
      _isPlayerReady = false; // Reset player state
      _isLoading = true; // Start loading immediately for next video
    });
    _initializePlayer(nextVideo.id);
  }

  @override
  void dispose() {
    _disposeControllers();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upNextVideos =
        widget.playlist.where((v) => v.id != _currentVideo.id).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Now Playing')),
      body: Column(
        children: [
          // 1. The Player Area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // A. The Player (Only visible when ready)
                  if (_isPlayerReady && _chewieController != null)
                    Chewie(controller: _chewieController!),

                  // B. The Thumbnail & Play Button (Visible when NOT ready)
                  if (!_isPlayerReady) ...[
                    Image.network(
                      _currentVideo.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Container(color: Colors.grey[900]),
                    ),

                    // Dark Overlay
                    Container(color: Colors.black38),

                    // Play Button or Spinner
                    if (_isLoading)
                      const CircularProgressIndicator(color: Color(0xFFD4AF37))
                    else
                      IconButton(
                        iconSize: 64,
                        icon: const Icon(Icons.play_circle_fill,
                            color: Color(0xFFD4AF37)),
                        onPressed: () => _initializePlayer(_currentVideo.id),
                      ),
                  ],

                  // C. Error Message
                  if (_errorMessage != null)
                    Container(
                      color: Colors.black87,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  _initializePlayer(_currentVideo.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text("Retry"),
                            )
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),

          // 2. The List
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView(
                children: [
                  VideoDescriptionWidget(video: _currentVideo),
                  const Divider(),
                  RelatedVideosList(
                    relatedVideos: upNextVideos,
                    onVideoTap: _playNextVideo,
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
