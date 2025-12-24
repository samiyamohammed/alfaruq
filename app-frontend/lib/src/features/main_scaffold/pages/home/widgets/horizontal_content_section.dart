import 'dart:async';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/book_detail_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/iqra_library_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/prophet_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HorizontalContentSection extends ConsumerStatefulWidget {
  final String title;
  final List<FeedItem> items;
  final bool isPortrait;
  final bool isLandscape;
  final VoidCallback? onSeeAll;

  const HorizontalContentSection({
    super.key,
    required this.title,
    required this.items,
    this.isPortrait = false,
    this.isLandscape = false,
    this.onSeeAll,
  });

  @override
  ConsumerState<HorizontalContentSection> createState() =>
      _HorizontalContentSectionState();
}

class _HorizontalContentSectionState
    extends ConsumerState<HorizontalContentSection> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
    });
  }

  void _startAutoSlide() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_scrollController.hasClients) {
        final currentScroll = _scrollController.offset;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final double itemWidth = widget.isPortrait ? 120.0 : 180.0;
        final double separator = 12.0;
        final double slideDistance = itemWidth + separator;
        double targetScroll = currentScroll + slideDistance;

        if (targetScroll >= maxScroll + 10) {
          _scrollController.animateTo(0,
              duration: const Duration(seconds: 1), curve: Curves.easeInOut);
        } else {
          _scrollController.animateTo(targetScroll,
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn);
        }
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.isPortrait ? 120 : 180;
    final double height = widget.isPortrait ? 180 : 140;
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                      color: Color(0xFFCFB56C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: widget.onSeeAll,
                  child: const Text("See All",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        SizedBox(
          height: height,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            separatorBuilder: (c, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final bool isFav = bookmarkedIds.contains(item.id);

              return GestureDetector(
                onTap: () {
                  if (item.type == 'PROPHET_HISTORY') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProphetHistoryScreen(contentId: item.id)));
                  } else if (item.type == 'BOOK') {
                    if (item.pdfUrl != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookDetailScreen(book: item)));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => IqraLibraryScreen(
                                  initialTabIndex: 1,
                                  targetedBookId: item.id)));
                    }
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ContentPlayerScreen(
                                contentId: item.id,
                                relatedContent: widget.items)));
                  }
                },
                child: Container(
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF151E32),
                    image: DecorationImage(
                        image: NetworkImage(item.thumbnailUrl ?? ''),
                        fit: BoxFit.cover),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Gradient Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12)),
                            gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                  Colors.black.withOpacity(0.9)
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.5, 1.0]),
                          ),
                        ),
                      ),
                      // Bookmark Icon
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => ref
                              .read(bookmarksProvider.notifier)
                              .toggleBookmark(item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black)
                              ]),
                        ),
                      ),
                      if (item.price != null && item.price != '0.00')
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFCFB56C), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock,
                                    color: Color(0xFFCFB56C), size: 10),
                                const SizedBox(width: 4),
                                Text(
                                    "${double.tryParse(item.price!)?.toStringAsFixed(0)} ETB",
                                    style: const TextStyle(
                                        color: Color(0xFFCFB56C),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
