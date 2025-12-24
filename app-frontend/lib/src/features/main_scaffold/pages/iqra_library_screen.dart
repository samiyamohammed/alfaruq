import 'dart:async';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/book_detail_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class IqraLibraryScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final String? targetedBookId;

  const IqraLibraryScreen(
      {super.key, this.initialTabIndex = 0, this.targetedBookId});

  @override
  ConsumerState<IqraLibraryScreen> createState() => _IqraLibraryScreenState();
}

class _IqraLibraryScreenState extends ConsumerState<IqraLibraryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedTabIndex;
  String _selectedGenre = "All";
  final ScrollController _genreScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  Timer? _genreAutoScrollTimer;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGenreAutoScroll();
    });
  }

  void _startGenreAutoScroll() {
    _genreAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_genreScrollController.hasClients) {
        final current = _genreScrollController.offset;
        final max = _genreScrollController.position.maxScrollExtent;
        final target = current + 100;
        if (target >= max + 20) {
          _genreScrollController.animateTo(0,
              duration: const Duration(seconds: 1), curve: Curves.easeInOut);
        } else {
          _genreScrollController.animateTo(target,
              duration: const Duration(seconds: 1), curve: Curves.linear);
        }
      }
    });
  }

  @override
  void dispose() {
    _genreAutoScrollTimer?.cancel();
    _genreScrollController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(feedContentProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.iqraReadListen,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            ref.read(bottomNavIndexProvider.notifier).state = 0;
          }
        },
      ),
      body: feedAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (err, stack) => Center(
            child: Text("${l10n.error}: $err",
                style: const TextStyle(color: Colors.white))),
        data: (allItems) {
          final books = allItems.where((i) => i.type == 'BOOK').toList();
          final Set<String> genres = {"All"};
          for (var book in books) {
            if (book.genre != null) {
              final splitGenres = book.genre!.split(',');
              for (var g in splitGenres) {
                if (g.trim().isNotEmpty) genres.add(g.trim());
              }
            }
          }
          final genreList = genres.toList();

          final filteredBooks = books.where((book) {
            bool matchesGenre = _selectedGenre == "All" ||
                (book.genre != null &&
                    book.genre!
                        .split(',')
                        .map((e) => e.trim())
                        .contains(_selectedGenre));
            final matchesTab = _selectedTabIndex == 0
                ? (book.pdfUrl != null)
                : (book.audioUrl != null);
            return matchesGenre && matchesTab;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                        child:
                            _buildTabButton(l10n.pdfBooks, Icons.menu_book, 0)),
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            _buildTabButton(l10n.audioBooks, Icons.headset, 1)),
                  ],
                ),
              ),
              _buildGenreBar(genreList),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildPdfGrid(filteredBooks, l10n)
                    : _buildAudioList(filteredBooks, l10n),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGenreBar(List<String> genreList) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: _genreScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: genreList.length,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final genre = genreList[index];
          final isSelected = _selectedGenre == genre;
          return GestureDetector(
            onTap: () => setState(() => _selectedGenre = genre),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFCFB56C).withOpacity(0.1)
                    : Colors.transparent,
                border: Border.all(
                    color:
                        isSelected ? const Color(0xFFCFB56C) : Colors.white24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(genre,
                  style: TextStyle(
                      color:
                          isSelected ? const Color(0xFFCFB56C) : Colors.white60,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCFB56C) : const Color(0xFF151E32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.black : Colors.white54, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white54,
                    fontWeight: FontWeight.w900,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioList(List<FeedItem> books, AppLocalizations l10n) {
    if (books.isEmpty)
      return Center(
          child: Text(l10n.noContentFound,
              style: const TextStyle(color: Colors.white54)));
    return ListView.separated(
      controller: _listScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      separatorBuilder: (c, i) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return _AudioBookTile(
            book: books[index],
            autoPlay: widget.targetedBookId == books[index].id);
      },
    );
  }

  Widget _buildPdfGrid(List<FeedItem> books, AppLocalizations l10n) {
    if (books.isEmpty)
      return Center(
          child: Text(l10n.noContentFound,
              style: const TextStyle(color: Colors.white54)));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => BookDetailScreen(book: book))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                      image: DecorationImage(
                          image: NetworkImage(book.thumbnailUrl ?? ''),
                          fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 8),
              Text(book.title,
                  maxLines: 2,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text(book.authorName ?? "Unknown Author",
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _AudioBookTile extends StatefulWidget {
  final FeedItem book;
  final bool autoPlay;
  const _AudioBookTile({required this.book, this.autoPlay = false});

  @override
  State<_AudioBookTile> createState() => _AudioBookTileState();
}

class _AudioBookTileState extends State<_AudioBookTile> {
  final AudioPlayer _player = AudioPlayer();
  bool _isExpanded = false;
  double _playbackSpeed = 1.0;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.book.audioUrl == null || widget.book.audioUrl!.isEmpty) return;

    try {
      // 1. Prepare the source with background metadata
      final audioSource = AudioSource.uri(
        Uri.parse(widget.book.audioUrl!),
        tag: MediaItem(
          id: widget.book.id,
          album: "Al-Faruk Library",
          title: widget.book.title,
          artist: widget.book.authorName ?? "Unknown Narrator",
          artUri: Uri.parse(widget.book.thumbnailUrl ?? ''),
        ),
      );

      // 2. Set source and wait for it to load
      await _player.setAudioSource(audioSource);

      // 3. Handle AutoPlay
      if (widget.autoPlay && mounted) {
        _player.play();
      }
    } catch (e) {
      debugPrint("⛔ Audio Player Error: $e");
      if (mounted) {
        setState(() => _loadError = true);
      }
    }
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0)
        _playbackSpeed = 1.25;
      else if (_playbackSpeed == 1.25)
        _playbackSpeed = 1.5;
      else if (_playbackSpeed == 1.5)
        _playbackSpeed = 2.0;
      else
        _playbackSpeed = 1.0;
    });
    _player.setSpeed(_playbackSpeed);
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: widget.autoPlay
                ? const Color(0xFFCFB56C)
                : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.book.thumbnailUrl ?? '',
                      width: 60, height: 85, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.book.title,
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(widget.book.authorName ?? "Narrator",
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),

                      // Progress Bar
                      StreamBuilder<Duration?>(
                        stream: _player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = _player.duration ?? Duration.zero;
                          return ProgressBar(
                            progress: position,
                            total: duration,
                            buffered: _player.bufferedPosition,
                            onSeek: (d) => _player.seek(d),
                            barHeight: 4,
                            baseBarColor: Colors.white10,
                            progressBarColor: const Color(0xFFCFB56C),
                            bufferedBarColor: Colors.white24,
                            thumbColor: const Color(0xFFCFB56C),
                            thumbRadius: 6,
                            timeLabelTextStyle: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSpeedButton(),
                _buildMainControls(),
                IconButton(
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54),
                    onPressed: () =>
                        setState(() => _isExpanded = !_isExpanded)),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.book.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton() {
    return GestureDetector(
      onTap: _cycleSpeed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white10, borderRadius: BorderRadius.circular(4)),
        child: Text("${_playbackSpeed}x",
            style: const TextStyle(
                color: Color(0xFFCFB56C),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildMainControls() {
    if (_loadError) {
      return const Icon(Icons.error_outline, color: Colors.redAccent);
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white70),
                onPressed: () => _player
                    .seek(Duration(seconds: _player.position.inSeconds - 10))),
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering)
              const SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFCFB56C))))
            else if (playing != true)
              IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.play_circle_filled,
                      color: Color(0xFFCFB56C)),
                  onPressed: _player.play)
            else
              IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.pause_circle_filled,
                      color: Color(0xFFCFB56C)),
                  onPressed: _player.pause),
            IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white70),
                onPressed: () => _player
                    .seek(Duration(seconds: _player.position.inSeconds + 10))),
          ],
        );
      },
    );
  }
}
