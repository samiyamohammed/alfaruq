import 'package:al_faruk_app/src/core/services/notification_service.dart';
import 'package:al_faruk_app/src/features/player/logic/global_player_provider.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FloatingPlayerOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const FloatingPlayerOverlay({super.key, required this.child});

  @override
  ConsumerState<FloatingPlayerOverlay> createState() =>
      _FloatingPlayerOverlayState();
}

class _FloatingPlayerOverlayState extends ConsumerState<FloatingPlayerOverlay> {
  Offset _offset = const Offset(20, 80);
  double _width = 210.0;
  bool _showControls = false;

  // A simple flag to "nudge" the UI when it first appears
  bool _isNudged = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(globalPlayerProvider);

    if (!playerState.isFloating || playerState.currentItem == null) {
      return widget.child;
    }

    // Force a micro-rebuild after the first build of the overlay to fix the "black screen"
    if (!_isNudged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isNudged = true);
      });
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double height = _width * (9 / 16);

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _offset = Offset(
                    (_offset.dx + details.delta.dx)
                        .clamp(0, screenWidth - _width),
                    (_offset.dy + details.delta.dy)
                        .clamp(0, MediaQuery.of(context).size.height - height),
                  );
                });
              },
              child: Material(
                elevation: 12,
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: _width,
                  height: height,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFFCFB56C).withOpacity(0.6),
                        width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // 1. VIDEO CONTENT (Uses GlobalKey to prevent black screen)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showControls = !_showControls),
                        child: AbsorbPointer(
                          absorbing: true,
                          child: playerState.isYouTube
                              ? YoutubePlayer(
                                  key: playerState.playerKey,
                                  controller: playerState.ytController!,
                                  showVideoProgressIndicator: false,
                                )
                              : Chewie(
                                  key: playerState.playerKey,
                                  controller: playerState.chewieController!,
                                ),
                        ),
                      ),

                      // 2. PROGRESS BAR
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildProgressBar(playerState),
                      ),

                      // 3. CONTROLS OVERLAY
                      if (_showControls)
                        Container(
                          color: Colors.black45,
                          child: Stack(
                            children: [
                              Center(
                                child: IconButton(
                                  icon: Icon(
                                    playerState.isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  onPressed: () => ref
                                      .read(globalPlayerProvider.notifier)
                                      .togglePlayPause(),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                left: 2,
                                child: IconButton(
                                  icon: const Icon(Icons.open_in_full,
                                      color: Colors.white, size: 18),
                                  onPressed: () {
                                    ref
                                        .read(globalPlayerProvider.notifier)
                                        .restoreFromPiP();
                                    NotificationService
                                        .navigatorKey.currentState
                                        ?.push(
                                      MaterialPageRoute(
                                        builder: (_) => ContentPlayerScreen(
                                          contentId:
                                              playerState.currentItem!.id,
                                          relatedContent:
                                              playerState.relatedContent,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white, size: 18),
                                  onPressed: () => ref
                                      .read(globalPlayerProvider.notifier)
                                      .closePlayer(),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 4. RESIZE HANDLE
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _width = (_width + details.delta.dx)
                                  .clamp(160, screenWidth * 0.9);
                            });
                          },
                          child: const Icon(Icons.drag_handle,
                              color: Colors.white24, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(GlobalPlayerState state) {
    if (state.isYouTube) {
      return StreamBuilder(
        stream: Stream.periodic(const Duration(milliseconds: 500)),
        builder: (context, snapshot) {
          if (state.ytController == null) return const SizedBox.shrink();
          final val = state.ytController!.value;
          // Fixed metadata duration check
          final duration = val.metaData.duration.inMilliseconds;
          final position = val.position.inMilliseconds;
          double progress = (duration > 0) ? position / duration : 0.0;
          return LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCFB56C)),
            minHeight: 2,
          );
        },
      );
    } else {
      return VideoProgressIndicator(
        state.videoController!,
        allowScrubbing: false,
        colors: const VideoProgressColors(
          playedColor: Color(0xFFCFB56C),
          bufferedColor: Colors.white24,
          backgroundColor: Colors.transparent,
        ),
      );
    }
  }
}
