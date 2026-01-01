import 'dart:async';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
import 'package:al_faruk_app/src/features/common/utils/guest_prompt.dart';
import 'package:al_faruk_app/src/features/history/data/history_repository.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/payment/data/payment_controller.dart';
import 'package:al_faruk_app/src/features/payment/screens/rental_options_sheet.dart';
import 'package:al_faruk_app/src/features/player/logic/global_player_provider.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  YoutubePlayerController? _ytController;

  // --- State ---
  bool _isPlayerInitialized = false;
  bool _isYouTubeMode = false;
  bool _isSeries = false;
  int _currentEpisodeIndex = 0;
  List<FeedItem> _playlist = [];
  String? _playlistRootId;
  late String _currentContentId;

  Timer? _historyTimer;
  FeedItem? _currentItemForHistory;
  String? _seriesTitleForHistory;

  bool _isParentLocked = false;
  bool _isCurrentItemLocked = false;
  bool _isCurrentItemVideoMissing = false;
  bool _isReturningFromPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _currentContentId = widget.contentId;
    ScreenProtector.preventScreenshotOn();

    // Set allowed orientations for this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Check if we are restoring from PiP to avoid restart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalState = ref.read(globalPlayerProvider);
      if (globalState.currentItem?.id == widget.contentId &&
          (globalState.videoController != null ||
              globalState.ytController != null)) {
        _restoreFromGlobal();
      }
    });
  }

  void _restoreFromGlobal() {
    final globalState = ref.read(globalPlayerProvider);
    setState(() {
      _videoController = globalState.videoController;
      _chewieController = globalState.chewieController;
      _ytController = globalState.ytController;
      _isYouTubeMode = globalState.isYouTube;
      _isPlayerInitialized = true;
      _currentItemForHistory = globalState.currentItem;
    });
    _startHistoryTracking(_currentItemForHistory!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
    _historyTimer?.cancel();

    // Reset orientation to Portrait only when leaving the screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Only dispose if we are NOT in floating mode
    final isFloating = ref.read(globalPlayerProvider).isFloating;
    if (!isFloating) {
      _disposePlayer();
    }

    WakelockPlus.disable();
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _isReturningFromPayment) {
      setState(() => _isReturningFromPayment = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFCFB56C)),
        ),
      );
      ref.invalidate(feedContentProvider);
      ref.invalidate(feedDetailsProvider(_currentContentId));
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
      ref.read(bottomNavIndexProvider.notifier).state = 1;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    if (state == AppLifecycleState.paused) {
      _saveProgress();
    }
  }

  void _disposePlayer() {
    _historyTimer?.cancel();
    _videoController?.dispose();
    _chewieController?.dispose();
    _ytController?.dispose();
    _videoController = null;
    _chewieController = null;
    _ytController = null;
    ref.read(globalPlayerProvider.notifier).closePlayer();
  }

  void _startHistoryTracking(FeedItem currentItem) {
    _currentItemForHistory = currentItem;
    _historyTimer?.cancel();
    _historyTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isYouTubeMode &&
          _videoController != null &&
          _videoController!.value.isPlaying) {
        _saveProgress();
      } else if (_isYouTubeMode &&
          _ytController != null &&
          _ytController!.value.isPlaying) {
        _saveProgress();
      }
    });
  }

  Future<void> _saveProgress() async {
    if (_currentItemForHistory == null) return;

    int position = 0;
    int duration = 0;

    if (_isYouTubeMode && _ytController != null) {
      position = _ytController!.value.position.inSeconds;
      duration = _ytController!.metadata.duration.inSeconds;
    } else if (_videoController != null &&
        _videoController!.value.isInitialized) {
      position = _videoController!.value.position.inSeconds;
      duration = _videoController!.value.duration.inSeconds;
    }

    if (position > 5) {
      await ref.read(historyRepositoryProvider).saveProgress(
            item: _currentItemForHistory!,
            positionSeconds: position,
            durationSeconds: duration,
            parentTitle: _seriesTitleForHistory,
          );
      ref.invalidate(watchHistoryProvider);
    }
  }

  // --- INITIALIZE NATIVE PLAYER (MP4/HLS) ---
  Future<void> _initializePlayer(String videoUrl, FeedItem item) async {
    if (_isPlayerInitialized) return;

    if (mounted) {
      setState(() {
        _isPlayerInitialized = false;
        _isYouTubeMode = false;
      });
    }
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      final savedSeconds =
          await ref.read(historyRepositoryProvider).getSavedPosition(item.id);
      if (savedSeconds > 0 &&
          savedSeconds < _videoController!.value.duration.inSeconds - 10) {
        await _videoController!.seekTo(Duration(seconds: savedSeconds));
      }

      // EXPERT FIX: Explicitly handle orientations to prevent landscape stickiness
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio > 0
            ? _videoController!.value.aspectRatio
            : 16 / 9,
        allowedScreenSleep: false,
        // When user exits fullscreen, force back to portrait
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        // Allow landscape in fullscreen
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFCFB56C),
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Colors.white24,
        ),
      );

      // Sync with Global Manager
      ref.read(globalPlayerProvider.notifier).setPlayer(
            item: item,
            related: widget.relatedContent,
            video: _videoController,
            chewie: _chewieController,
            isYouTube: false,
          );

      _startHistoryTracking(item);
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
      if (mounted) setState(() => _isPlayerInitialized = false);
    }
  }

  // --- INITIALIZE YOUTUBE PLAYER ---
  Future<void> _initializeYoutubePlayer(
      String youtubeUrl, FeedItem item) async {
    if (_isPlayerInitialized) return;

    if (mounted) {
      setState(() {
        _isPlayerInitialized = false;
        _isYouTubeMode = true;
      });
    }

    try {
      final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
      if (videoId == null) throw "Invalid YouTube URL";

      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      );

      // Sync with Global Manager
      ref.read(globalPlayerProvider.notifier).setPlayer(
            item: item,
            related: widget.relatedContent,
            yt: _ytController,
            isYouTube: true,
          );

      _startHistoryTracking(item);

      _ytController!.addListener(() {
        if (_isSeries &&
            _ytController!.value.playerState == PlayerState.ended) {
          _playNextEpisode();
        }
      });

      if (mounted) setState(() => _isPlayerInitialized = true);
    } catch (e) {
      debugPrint("YouTube Init Error: $e");
      if (mounted) setState(() => _isPlayerInitialized = false);
    }
  }

  void _playNextEpisode() async {
    await _saveProgress();
    if (_currentEpisodeIndex < _playlist.length - 1) {
      setState(() {
        _currentEpisodeIndex = _currentEpisodeIndex + 1;
        _isPlayerInitialized = false;
      });
      _evaluateCurrentItem();
    }
  }

  List<FeedItem> _extractEpisodes(FeedItem content) {
    if (content.type == 'SERIES') {
      List<FeedItem> allEpisodes = [];
      for (var season in content.children) {
        if (season.type == 'SEASON') {
          allEpisodes.addAll(season.children);
        } else if (season.type == 'EPISODE') {
          allEpisodes.add(season);
        }
      }
      return allEpisodes;
    } else if (content.type == 'SEASON') {
      return content.children;
    } else {
      return [content];
    }
  }

  void _setupContent(FeedItem content, {FeedItem? parentSeries}) {
    FeedItem rootToUse = parentSeries ?? content;
    _playlistRootId = rootToUse.id;
    List<FeedItem> extracted = _extractEpisodes(rootToUse);
    int index = extracted.indexWhere((e) => e.id == content.id);
    if (index != -1) {
      _playlist = extracted;
      _currentEpisodeIndex = index;
      _isSeries = true;
      _seriesTitleForHistory = rootToUse.title;
      _isParentLocked = rootToUse.isLocked;
    } else if (rootToUse.type == 'SERIES' && extracted.isNotEmpty) {
      _playlist = extracted;
      _currentEpisodeIndex = 0;
      _isSeries = true;
      _seriesTitleForHistory = rootToUse.title;
      _isParentLocked = rootToUse.isLocked;
    } else {
      _playlist = [content];
      _currentEpisodeIndex = 0;
      _isSeries = false;
      _seriesTitleForHistory = null;
      _isParentLocked = content.isLocked;
    }
    _evaluateCurrentItem();
  }

  void _evaluateCurrentItem() {
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

    if (_isParentLocked || currentItem.isLocked) {
      _disposePlayer();
      setState(() {
        _isCurrentItemLocked = true;
        _isCurrentItemVideoMissing = false;
        _isPlayerInitialized = false;
      });
      return;
    }

    if (currentItem.videoUrl != null && currentItem.videoUrl!.isNotEmpty) {
      if (_videoController?.dataSource != currentItem.videoUrl) {
        _initializePlayer(currentItem.videoUrl!, currentItem);
      }
      return;
    }

    if (currentItem.youtubeUrl != null && currentItem.youtubeUrl!.isNotEmpty) {
      _initializeYoutubePlayer(currentItem.youtubeUrl!, currentItem);
      return;
    }

    _disposePlayer();
    setState(() {
      _isCurrentItemLocked = false;
      _isCurrentItemVideoMissing = true;
      _isPlayerInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(feedDetailsProvider(_currentContentId));
    final globalFeedState = ref.watch(feedContentProvider);
    final List<FeedItem> globalFeed = globalFeedState.valueOrNull ?? [];
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};
    final playerKey = ref.watch(globalPlayerProvider).playerKey;

    return contentAsync.when(
      loading: () => const Scaffold(
          backgroundColor: Color(0xFF0B101D),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFCFB56C)))),
      error: (err, stack) => Scaffold(
          backgroundColor: const Color(0xFF0B101D),
          body: Center(
              child: Text("Error: $err",
                  style: const TextStyle(color: Colors.white)))),
      data: (content) {
        AsyncValue<FeedItem>? parentAsync;
        if ((content.type == 'EPISODE' || content.type == 'SEASON') &&
            content.parentId != null) {
          parentAsync = ref.watch(feedDetailsProvider(content.parentId!));
        }

        return parentAsync?.when(
              loading: () => const Scaffold(
                  backgroundColor: Color(0xFF0B101D),
                  body: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFCFB56C)))),
              error: (e, s) => _playerLogicWrapper(
                  content, null, null, globalFeed, bookmarkedIds, playerKey),
              data: (parent) {
                if (parent.parentId != null) {
                  final grandParentAsync =
                      ref.watch(feedDetailsProvider(parent.parentId!));
                  return grandParentAsync.when(
                      loading: () => const Scaffold(
                          backgroundColor: Color(0xFF0B101D),
                          body: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFCFB56C)))),
                      error: (e, s) => _playerLogicWrapper(content, parent,
                          null, globalFeed, bookmarkedIds, playerKey),
                      data: (grandParent) => _playerLogicWrapper(
                          content,
                          parent,
                          grandParent,
                          globalFeed,
                          bookmarkedIds,
                          playerKey));
                }
                return _playerLogicWrapper(content, parent, null, globalFeed,
                    bookmarkedIds, playerKey);
              },
            ) ??
            _playerLogicWrapper(
                content, null, null, globalFeed, bookmarkedIds, playerKey);
      },
    );
  }

  /// Handles Youtube fullscreen logic and Native rendering logic
  Widget _playerLogicWrapper(
      FeedItem content,
      FeedItem? parent,
      FeedItem? grandParent,
      List<FeedItem> globalFeed,
      Set<String> bookmarkedIds,
      Key? playerKey) {
    // YOUTUBE MODE
    if (_isYouTubeMode && _ytController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          key: playerKey,
          controller: _ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFFCFB56C),
          progressColors: const ProgressBarColors(
            playedColor: Color(0xFFCFB56C),
            handleColor: Colors.white,
          ),
        ),
        builder: (context, player) {
          return PopScope(
            onPopInvoked: (didPop) => SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp]),
            child: Scaffold(
              backgroundColor: const Color(0xFF0B101D),
              body: SafeArea(
                child: _buildScrollableLayout(content, parent, grandParent,
                    globalFeed, bookmarkedIds, playerKey, player),
              ),
            ),
          );
        },
      );
    }

    // NATIVE MODE - EXPERT FIX: Wrapping in ValueListenableBuilder for texture persistence
    // This prevents the PiP screen from being frozen until clicked.
    Widget nativePlayer = const Center(
        child: CircularProgressIndicator(color: Color(0xFFCFB56C)));

    if (_isPlayerInitialized &&
        _chewieController != null &&
        _videoController != null) {
      nativePlayer = ValueListenableBuilder(
        valueListenable: _videoController!,
        builder: (context, value, child) {
          return Chewie(key: playerKey, controller: _chewieController!);
        },
      );
    }

    return PopScope(
      onPopInvoked: (didPop) =>
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B101D),
        body: SafeArea(
          child: _buildScrollableLayout(
            content,
            parent,
            grandParent,
            globalFeed,
            bookmarkedIds,
            playerKey,
            nativePlayer,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableLayout(
      FeedItem content,
      FeedItem? parent,
      FeedItem? grandParent,
      List<FeedItem> globalFeed,
      Set<String> bookmarkedIds,
      Key? playerKey,
      Widget playerWidget) {
    final FeedItem rootObj = grandParent ?? parent ?? content;
    final bool isFav = bookmarkedIds.contains(rootObj.id);

    if (_playlist.isEmpty || _playlistRootId != rootObj.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupContent(content, parentSeries: rootObj);
      });
    } else {
      _isParentLocked = rootObj.isLocked;
    }

    final currentItem =
        _playlist.isNotEmpty ? _playlist[_currentEpisodeIndex] : content;

    List<FeedItem> displayRelated = widget.relatedContent;
    final targetType = (content.type == 'EPISODE' || content.type == 'SEASON')
        ? 'SERIES'
        : content.type;

    if (displayRelated.isEmpty) {
      displayRelated = globalFeed
          .where((i) =>
              i.type == targetType && i.id != content.id && i.id != rootObj.id)
          .toList();
    } else {
      displayRelated = displayRelated.where((i) => i.id != content.id).toList();
    }

    // Detect if we are in fullscreen (Landscape)
    bool isFullScreen = false;
    if (_isYouTubeMode) {
      isFullScreen = _ytController?.value.isFullScreen ?? false;
    } else {
      isFullScreen = _chewieController?.isFullScreen ?? false;
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCurrentItemLocked)
                  _buildLockedUI(rootObj)
                else if (_isCurrentItemVideoMissing)
                  _buildMissingVideoUI()
                else
                  playerWidget,
                if (!isFullScreen)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.black45, shape: BoxShape.circle),
                        child:
                            const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),
                if (_isPlayerInitialized &&
                    !_isCurrentItemLocked &&
                    !_isCurrentItemVideoMissing &&
                    !isFullScreen)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        // Switch state in global provider
                        ref.read(globalPlayerProvider.notifier).switchToPiP();
                        // Exit screen to let overlay take over GlobalKey
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.picture_in_picture_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!isFullScreen)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(rootObj.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))),
                    IconButton(
                      onPressed: () => ref
                          .read(bookmarksProvider.notifier)
                          .toggleBookmark(rootObj),
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white),
                    ),
                  ],
                ),
                if (_isSeries)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("Playing: ${currentItem.title}",
                        style: const TextStyle(
                            color: Color(0xFFCFB56C), fontSize: 14)),
                  ),
                const SizedBox(height: 12),
                Text(rootObj.description,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4)),
                const Divider(color: Colors.white12, height: 32),
                if (_isSeries) ...[
                  const Text("Seasons & Episodes",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSeasonsUI(rootObj, bookmarkedIds),
                  const Divider(color: Colors.white12, height: 32),
                ],
                if (displayRelated.isNotEmpty) ...[
                  const Text("Related Content",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRelatedList(displayRelated),
                ]
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSeasonsUI(FeedItem rootContent, Set<String> bookmarkedIds) {
    if (rootContent.children.isEmpty) {
      if (_playlist.length > 1) {
        return Column(
          children: _playlist.asMap().entries.map((entry) {
            return _buildEpisodeTile(
                entry.value, entry.key, bookmarkedIds.contains(entry.value.id));
          }).toList(),
        );
      }
      return const Text("No episodes available.",
          style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: rootContent.children.map((season) {
        if (season.type != 'SEASON') {
          return _buildEpisodeTile(season, _findGlobalIndex(season.id),
              bookmarkedIds.contains(season.id));
        }
        final bool isSeasonFav = bookmarkedIds.contains(season.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                      child: Text(season.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  IconButton(
                    onPressed: () => ref
                        .read(bookmarksProvider.notifier)
                        .toggleBookmark(season),
                    icon: Icon(
                        isSeasonFav ? Icons.favorite : Icons.favorite_border,
                        color: isSeasonFav ? Colors.red : Colors.white54,
                        size: 20),
                  ),
                ],
              ),
              iconColor: const Color(0xFFCFB56C),
              collapsedIconColor: Colors.white54,
              initiallyExpanded: true,
              children: season.children.map((episode) {
                return _buildEpisodeTile(episode, _findGlobalIndex(episode.id),
                    bookmarkedIds.contains(episode.id));
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  int _findGlobalIndex(String id) => _playlist.indexWhere((e) => e.id == id);

  Widget _buildEpisodeTile(FeedItem episode, int globalIndex, bool isFav) {
    if (globalIndex == -1) return const SizedBox();
    final isPlaying = globalIndex == _currentEpisodeIndex;
    final isLocked = _isParentLocked || episode.isLocked;

    return ListTile(
      onTap: () async {
        if (isPlaying) return;
        await _saveProgress();
        setState(() {
          _currentEpisodeIndex = globalIndex;
          _isPlayerInitialized = false;
        });
        _disposePlayer();
        _evaluateCurrentItem();
      },
      leading: Icon(
        isPlaying
            ? Icons.play_circle_fill
            : (isLocked ? Icons.lock : Icons.play_circle_outline),
        color: isPlaying ? const Color(0xFFCFB56C) : Colors.white54,
      ),
      title: Text(episode.title,
          style: TextStyle(
              color: isPlaying ? const Color(0xFFCFB56C) : Colors.white,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(episode.duration),
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                ref.read(bookmarksProvider.notifier).toggleBookmark(episode),
            child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedList(List<FeedItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => ContentPlayerScreen(
                        contentId: item.id, relatedContent: items)));
          },
          child: Row(
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item.thumbnailUrl ?? '',
                      width: 120, height: 68, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(item.type,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissingVideoUI() {
    return const Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videocam_off, color: Colors.grey, size: 50),
        SizedBox(height: 12),
        Text("Video Unavailable",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    ));
  }

  Widget _buildLockedUI(FeedItem content) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, color: Color(0xFFCFB56C), size: 40),
        const SizedBox(height: 8),
        const Text("Premium Content",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final authState = ref.read(authControllerProvider);
            if (authState == AuthState.guest) {
              GuestPrompt.show(context, ref);
              return;
            }
            if (content.pricingTier == null) return;
            final result = await showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => RentalOptionsSheet(
                    contentId: content.id, pricing: content.pricingTier!));
            if (result != null && result['initiate'] == true) {
              setState(() => _isReturningFromPayment = true);
              ref.read(paymentControllerProvider.notifier).buyContent(
                  contentId: content.id, durationDays: result['days']);
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFB56C),
              foregroundColor: Colors.black),
          child: const Text("Rent Now"),
        ),
      ],
    ));
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return "";
    final d = Duration(seconds: seconds);
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
