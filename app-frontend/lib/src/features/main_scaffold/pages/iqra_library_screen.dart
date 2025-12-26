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
import 'package:audio_session/audio_session.dart';

final globalAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  return player;
});

final currentPlayingBookIdProvider = StateProvider<String?>((ref) => null);

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
    _setupAudioSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGenreAutoScroll();
    });
  }

  Future<void> _setupAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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
    // Retrieve bookmarked IDs for the PDF grid
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};

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
                    ? _buildPdfGrid(filteredBooks, l10n, bookmarkedIds)
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
        return _AudioBookTile(book: books[index]);
      },
    );
  }

  Widget _buildPdfGrid(
      List<FeedItem> books, AppLocalizations l10n, Set<String> bookmarkedIds) {
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
        final bool isFav = bookmarkedIds.contains(book.id);

        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => BookDetailScreen(book: book))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                          image: DecorationImage(
                              image: NetworkImage(book.thumbnailUrl ?? ''),
                              fit: BoxFit.cover)),
                    ),
                    // Added Favorite Button overlay for PDF items
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(bookmarksProvider.notifier)
                            .toggleBookmark(book),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
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

class _AudioBookTile extends ConsumerWidget {
  final FeedItem book;
  const _AudioBookTile({required this.book});

  Future<void> _handlePlay(
      WidgetRef ref, AudioPlayer player, String? currentId) async {
    final bool isThisBook = currentId == book.id;

    if (isThisBook) {
      player.playing ? await player.pause() : await player.play();
    } else {
      try {
        await player.stop();
        ref.read(currentPlayingBookIdProvider.notifier).state = book.id;

        final source = AudioSource.uri(
          Uri.parse(book.audioUrl!),
          tag: MediaItem(
            id: book.id,
            album: "Al-Faruk Library",
            title: book.title,
            artist: book.authorName ?? "Unknown Narrator",
            artUri: Uri.parse(book.thumbnailUrl ?? ''),
          ),
        );

        await player.setAudioSource(source);
        await player.play();
      } catch (e) {
        debugPrint("Audio Playback Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(globalAudioPlayerProvider);
    final currentBookId = ref.watch(currentPlayingBookIdProvider);
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};
    final bool isFav = bookmarkedIds.contains(book.id);

    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
        final bool isThisBookPlaying = mediaItem?.id == book.id;

        if (isThisBookPlaying && currentBookId != book.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentPlayingBookIdProvider.notifier).state = book.id;
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151E32),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isThisBookPlaying
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
                      child: Image.network(book.thumbnailUrl ?? '',
                          width: 60, height: 85, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title,
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(book.authorName ?? "Narrator",
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 12),
                          if (isThisBookPlaying)
                            StreamBuilder<Duration?>(
                              stream: player.positionStream,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                final duration =
                                    player.duration ?? Duration.zero;
                                return ProgressBar(
                                  progress: position,
                                  total: duration,
                                  buffered: player.bufferedPosition,
                                  onSeek: player.seek,
                                  barHeight: 4,
                                  baseBarColor: Colors.white10,
                                  progressBarColor: const Color(0xFFCFB56C),
                                  thumbColor: const Color(0xFFCFB56C),
                                  thumbRadius: 6,
                                  timeLabelTextStyle: const TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                );
                              },
                            )
                          else
                            const SizedBox(
                                height: 20,
                                child: Divider(color: Colors.white10)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(bookmarksProvider.notifier)
                          .toggleBookmark(book),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white38,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpeedButton(player, isThisBookPlaying),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10,
                              color: Colors.white70),
                          onPressed: isThisBookPlaying
                              ? () => player.seek(Duration(
                                  seconds: player.position.inSeconds - 10))
                              : null,
                        ),
                        StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final playing = playerState?.playing ?? false;
                            final processing = playerState?.processingState;

                            bool showPause = isThisBookPlaying && playing;
                            bool isLoading = isThisBookPlaying &&
                                (processing == ProcessingState.loading ||
                                    processing == ProcessingState.buffering);

                            if (isLoading) {
                              return const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFCFB56C))));
                            }

                            return IconButton(
                              iconSize: 48,
                              icon: Icon(
                                  showPause
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: const Color(0xFFCFB56C)),
                              onPressed: () =>
                                  _handlePlay(ref, player, currentBookId),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10,
                              color: Colors.white70),
                          onPressed: isThisBookPlaying
                              ? () => player.seek(Duration(
                                  seconds: player.position.inSeconds + 10))
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedButton(AudioPlayer player, bool isActive) {
    return StreamBuilder<double>(
        stream: player.speedStream,
        builder: (context, snapshot) {
          final speed = snapshot.data ?? 1.0;
          return GestureDetector(
            onTap: isActive
                ? () {
                    double newSpeed = speed + 0.25;
                    if (newSpeed > 2.0) newSpeed = 1.0;
                    player.setSpeed(newSpeed);
                    HapticFeedback.selectionClick();
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4)),
              child: Text("${speed}x",
                  style: TextStyle(
                      color:
                          isActive ? const Color(0xFFCFB56C) : Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          );
        });
  }
}
