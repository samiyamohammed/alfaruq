import 'dart:async';
import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/book_detail_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class IqraLibraryScreen extends ConsumerStatefulWidget {
  final int initialTabIndex; // 0 for PDF, 1 for Audio
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
  bool _hasScrolledToTarget = false;

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

  void _scrollToTargetedBook(List<FeedItem> filteredBooks) {
    if (!_hasScrolledToTarget &&
        widget.targetedBookId != null &&
        _selectedTabIndex == 1) {
      final index =
          filteredBooks.indexWhere((b) => b.id == widget.targetedBookId);
      if (index != -1) {
        _hasScrolledToTarget = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_listScrollController.hasClients) {
            final double offset = index * 320.0;
            _listScrollController.animateTo(
              offset,
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
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
    // 2. Initialize Localization
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(feedContentProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.iqraReadListen, // Localized Title
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
            bool matchesGenre = false;
            if (_selectedGenre == "All") {
              matchesGenre = true;
            } else if (book.genre != null) {
              List<String> bookGenres =
                  book.genre!.split(',').map((e) => e.trim()).toList();
              matchesGenre = bookGenres.contains(_selectedGenre);
            }

            // Index 0 = PDF, Index 1 = Audio
            final matchesTab = _selectedTabIndex == 0
                ? (book.pdfUrl != null)
                : (book.audioUrl != null);
            return matchesGenre && matchesTab;
          }).toList();

          _scrollToTargetedBook(filteredBooks);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildTabButton(
                            l10n.pdfBooks, Icons.menu_book, 0)), // Localized
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTabButton(
                            l10n.audioBooks, Icons.headset, 1)), // Localized
                  ],
                ),
              ),
              SizedBox(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.white10 : Colors.transparent,
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFCFB56C)
                                : Colors.white60,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
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

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCFB56C) : const Color(0xFF151E32),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white54),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white54,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioList(List<FeedItem> books, AppLocalizations l10n) {
    if (books.isEmpty)
      return Center(
          child: Text(l10n.noContentFound, // Localized
              style: const TextStyle(color: Colors.white54)));
    return ListView.separated(
      controller: _listScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: books.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final book = books[index];
        final bool shouldAutoPlay = widget.targetedBookId == book.id;
        return _AudioBookTile(book: book, autoPlay: shouldAutoPlay);
      },
    );
  }

  Widget _buildPdfGrid(List<FeedItem> books, AppLocalizations l10n) {
    if (books.isEmpty)
      return Center(
          child: Text(l10n.noContentFound, // Localized
              style: const TextStyle(color: Colors.white54)));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
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
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                        image: NetworkImage(book.thumbnailUrl ?? ''),
                        fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text(book.authorName ?? "Unknown Author",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      _togglePlay();
    }
  }

  Future<void> _togglePlay() async {
    if (_controller == null) {
      if (widget.book.audioUrl == null) return;
      if (mounted) setState(() => _isInitialized = false);
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.book.audioUrl!));
      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) setState(() => _isPlaying = _controller!.value.isPlaying);
      });
      if (mounted) setState(() => _isInitialized = true);
    }
    _isPlaying ? _controller!.pause() : _controller!.play();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int minutes =
        widget.book.duration != null ? (widget.book.duration! / 60).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(4),
        border: widget.autoPlay
            ? Border.all(color: const Color(0xFFCFB56C), width: 1)
            : Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    image: DecorationImage(
                        image: NetworkImage(widget.book.thumbnailUrl ?? ''),
                        fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _togglePlay,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFCFB56C),
                    child: (!_isInitialized && _controller != null)
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volume_up,
                              color: Color(0xFFCFB56C), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 20,
                        child: _isInitialized
                            ? VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFFCFB56C),
                                  backgroundColor: Colors.white10,
                                  bufferedColor: Colors.white24,
                                ),
                              )
                            : LinearProgressIndicator(
                                value: 0,
                                backgroundColor: Colors.white10,
                                color:
                                    const Color(0xFFCFB56C).withOpacity(0.3)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_isInitialized)
                            ValueListenableBuilder(
                              valueListenable: _controller!,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                return Text(_formatDuration(value.position),
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 10));
                              },
                            )
                          else
                            const Text("0:00",
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                          const Text("0:00",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("by ${widget.book.authorName ?? 'Unknown'}",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text("$minutes min audio",
                    style: const TextStyle(
                        color: Color(0xFFCFB56C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 12),
                Text(
                  widget.book.description,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Row(
                    children: [
                      Text(
                        _isExpanded ? "Read less" : "Read more",
                        style: const TextStyle(
                            color: Color(0xFFCFB56C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFFCFB56C),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
