import 'dart:async';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/payment/data/payment_controller.dart';
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

class _ContentPlayerScreenState extends ConsumerState<ContentPlayerScreen>
    with WidgetsBindingObserver {
  // --- Controllers ---
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // --- State ---
  bool _isPlayerInitialized = false;
  bool _isSeries = false;
  int _currentEpisodeIndex = 0;
  List<FeedItem> _playlist = [];

  // Track the ID being viewed to refresh correctly
  late String _currentContentId;

  // --- UI Flags (The Brain) ---
  bool _isCurrentItemLocked = false;
  bool _isCurrentItemVideoMissing = false;

  // Track payment return
  bool _isReturningFromPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _currentContentId = widget.contentId;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposePlayer();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // --- 1. HANDLE PAYMENT RETURN REFRESH ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isReturningFromPayment) {
      print("🔄 User returned from payment...");
      // Refresh this specific content
      ref.invalidate(feedDetailsProvider(_currentContentId));
      // Refresh the home/grid lists so the lock icon disappears there too
      ref.invalidate(feedContentProvider);

      setState(() {
        _isReturningFromPayment = false;
      });
    }
  }

  void _disposePlayer() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
  }

  // --- 2. INITIALIZE PLAYER (Only called if safe) ---
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
            child:
                Text(errorMessage, style: const TextStyle(color: Colors.white)),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFCFB56C),
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Colors.white24,
        ),
      );

      // Auto-play next episode listener
      _videoController!.addListener(() {
        if (_isSeries &&
            _videoController!.value.isInitialized &&
            !_videoController!.value.isPlaying &&
            _videoController!.value.position >=
                _videoController!.value.duration) {
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
      setState(() {
        _currentEpisodeIndex = _currentEpisodeIndex + 1;
      });
      _evaluateCurrentItem();
    }
  }

  // --- 3. DATA SETUP ---
  void _setupContent(FeedItem item) {
    if (item.type == 'SERIES') {
      _isSeries = true;
      _playlist = item.children; // Can be empty
    } else {
      _isSeries = false;
      _playlist = [item];
    }
    // Run the evaluation logic immediately
    _evaluateCurrentItem();
  }

  // --- 4. CORE LOGIC: CHECK LOCK & URL ---
  void _evaluateCurrentItem() {
    // A. Empty Playlist Check
    if (_playlist.isEmpty) {
      _disposePlayer();
      setState(() {
        _isCurrentItemLocked = false;
        _isCurrentItemVideoMissing = true;
        _isPlayerInitialized = false;
      });
      return;
    }

    final currentItem = _playlist[_currentEpisodeIndex];

    // B. LOCK CHECK (Priority 1)
    // If locked, we show purchase UI immediately. We don't care if video exists yet.
    if (currentItem.isLocked) {
      _disposePlayer();
      setState(() {
        _isCurrentItemLocked = true;
        _isCurrentItemVideoMissing = false;
        _isPlayerInitialized = false;
      });
      return;
    }

    // C. VIDEO URL CHECK (Priority 2)
    // If unlocked, but no video URL, handle gracefully.
    if (currentItem.videoUrl == null || currentItem.videoUrl!.isEmpty) {
      _disposePlayer();
      setState(() {
        _isCurrentItemLocked = false;
        _isCurrentItemVideoMissing = true;
        _isPlayerInitialized = false;
      });
      return;
    }

    // D. PLAY VIDEO (Priority 3)
    // Unlocked AND has Video -> Play it.
    setState(() {
      _isCurrentItemLocked = false;
      _isCurrentItemVideoMissing = false;
    });

    // Only re-initialize if we aren't already playing this specific URL
    if (_videoController?.dataSource != currentItem.videoUrl) {
      _initializePlayer(currentItem.videoUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(feedDetailsProvider(_currentContentId));

    // Error Listener for Payment
    ref.listen(paymentControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Payment failed: ${next.error}"),
              backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      body: SafeArea(
        child: contentAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
          error: (err, stack) => Center(
              child: Text("Error: $err",
                  style: const TextStyle(color: Colors.white))),
          data: (content) {
            // --- SYNC DATA LOGIC ---
            // 1. If this is the first load OR we switched to a totally different series/movie
            if (_playlist.isEmpty ||
                (_isSeries &&
                    _playlist.isNotEmpty &&
                    _playlist.first.parentId != content.id)) {
              _setupContent(content);
            }
            // 2. If it's a refresh (e.g. after payment), update the existing playlist
            else {
              if (content.type == 'SERIES') {
                _playlist = content.children;
              } else {
                _playlist = [content];
              }

              // Use PostFrameCallback to safely trigger state changes during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _evaluateCurrentItem();
              });
            }

            final currentItem = _playlist.isNotEmpty
                ? _playlist[_currentEpisodeIndex]
                : content;

            return Column(
              children: [
                // --- PLAYER AREA ---
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // STATE A: Locked -> Show Buy Button
                        if (_isCurrentItemLocked)
                          _buildLockedUI(currentItem.id)

                        // STATE B: Missing Video -> Show Message
                        else if (_isCurrentItemVideoMissing)
                          _buildMissingVideoUI()

                        // STATE C: Player Ready -> Show Video
                        else if (_isPlayerInitialized &&
                            _chewieController != null)
                          Chewie(controller: _chewieController!)

                        // STATE D: Loading
                        else
                          const CircularProgressIndicator(
                              color: Color(0xFFCFB56C)),

                        // Back Button (Always on top)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- INFO AREA ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        content.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      if (_isSeries)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Playing: ${currentItem.title}",
                            style: const TextStyle(
                                color: Color(0xFFCFB56C), fontSize: 14),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        content.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      const Divider(color: Colors.white12, height: 32),
                      Text(
                        _isSeries
                            ? "Episodes"
                            : "Related ${content.type == 'DOCUMENTARY' ? 'Documentaries' : 'Movies'}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_isSeries)
                        _buildEpisodesList()
                      else
                        _buildRelatedList(content.id),
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
    if (_playlist.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No episodes available yet.",
            style: TextStyle(color: Colors.grey)),
      );
    }

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
              // Resetting init state ensures loading spinner shows while switching
              _isPlayerInitialized = false;
            });
            _disposePlayer();
            _evaluateCurrentItem(); // Run logic for new selection
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPlaying
                  ? const Color(0xFFCFB56C).withOpacity(0.1)
                  : const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      isPlaying ? const Color(0xFFCFB56C) : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  isPlaying
                      ? Icons.play_circle_fill
                      : (episode.isLocked
                          ? Icons.lock
                          : Icons.play_circle_outline),
                  color: isPlaying ? const Color(0xFFCFB56C) : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    episode.title,
                    style: TextStyle(
                      color: isPlaying ? const Color(0xFFCFB56C) : Colors.white,
                      fontWeight:
                          isPlaying ? FontWeight.bold : FontWeight.normal,
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
    final related =
        widget.relatedContent.where((i) => i.id != currentId).toList();

    if (related.isEmpty) {
      return const Text("No related content found.",
          style: TextStyle(color: Colors.white38));
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ContentPlayerScreen(
                  contentId: item.id,
                  relatedContent: widget.relatedContent,
                ),
              ),
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.thumbnailUrl ?? '',
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                      width: 120, height: 68, color: Colors.grey[900]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.isLocked) ...[
                          const Icon(Icons.lock,
                              color: Color(0xFFCFB56C), size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          item.type,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
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

  // --- MISSING VIDEO UI ---
  Widget _buildMissingVideoUI() {
    return Center(
      child: Container(
        color: Colors.black87,
        width: double.infinity,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.grey, size: 50),
            SizedBox(height: 12),
            Text(
              "Video Unavailable",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "This content is not yet available for streaming.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOCKED UI ---
  Widget _buildLockedUI(String contentId) {
    final paymentState = ref.watch(paymentControllerProvider);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: Colors.black87,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  color: Color(0xFFCFB56C), size: 40),
              const SizedBox(height: 8),
              const Text(
                "Premium Content",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Rent for 10 days to unlock.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                height: 40,
                child: ElevatedButton(
                  onPressed: paymentState.isLoading
                      ? null
                      : () {
                          setState(() => _isReturningFromPayment = true);
                          ref
                              .read(paymentControllerProvider.notifier)
                              .buyContent(contentId);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCFB56C),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: paymentState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Text(
                          "Rent Now",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return "";
    final d = Duration(seconds: seconds);
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
