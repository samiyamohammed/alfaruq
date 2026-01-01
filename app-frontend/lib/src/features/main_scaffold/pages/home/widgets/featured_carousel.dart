import 'dart:async';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
import 'package:al_faruk_app/src/features/common/utils/guest_prompt.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/trailer_player_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeaturedCarousel extends ConsumerStatefulWidget {
  final List<FeedItem> items;
  const FeaturedCarousel({super.key, required this.items});

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  late PageController _pageController;
  late Timer _timer;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.items.length * 1000;
    _pageController =
        PageController(viewportFraction: 1.0, initialPage: initialPage);
    _currentPage = initialPage.toDouble();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentRealIndex = _currentPage.round() % widget.items.length;
    final currentItem = widget.items[currentRealIndex];
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};
    final bool isFav = bookmarkedIds.contains(currentItem.id);

    return Column(
      children: [
        SizedBox(
          height: 480,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final int actualIndex = index % widget.items.length;
              final item = widget.items[actualIndex];

              double scale = 1.0;
              if (_pageController.position.haveDimensions) {
                scale = (1 - ((_currentPage - index).abs() * 0.15))
                    .clamp(0.85, 1.0);
              }

              return Transform.scale(
                scale: scale,
                child: _buildCarouselItem(item),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Icons.info_outline, l10n.detail, Colors.white, () {
                HomePageStateHelper.showDetailDialog(
                    context, currentItem, l10n);
              }),
              _buildWatchButton(l10n, currentItem),
              _actionButton(
                isFav ? Icons.favorite : Icons.favorite_border,
                isFav ? "Saved" : l10n.addList,
                isFav ? const Color(0xFFCFB56C) : Colors.white,
                () {
                  final authState = ref.read(authControllerProvider);
                  if (authState == AuthState.guest) {
                    GuestPrompt.show(context, ref);
                    return;
                  }
                  ref
                      .read(bookmarksProvider.notifier)
                      .toggleBookmark(currentItem);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildWatchButton(AppLocalizations l10n, FeedItem item) {
    return Container(
      width: 180,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCFB56C).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentPlayerScreen(contentId: item.id),
            ),
          );
        },
        icon:
            const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
        label: Text(
          l10n.watchNow.toUpperCase(),
          style:
              const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCFB56C),
          foregroundColor: Colors.black,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildCarouselItem(FeedItem item) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(item.thumbnailUrl ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.25, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicators() {
    final currentRealIndex = _currentPage.round() % widget.items.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.items.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentRealIndex == index ? 28 : 8,
          height: 4,
          decoration: BoxDecoration(
            color: currentRealIndex == index
                ? const Color(0xFFCFB56C)
                : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class HomePageStateHelper {
  static String _formatDuration(int? totalSeconds) {
    if (totalSeconds == null) return "Unknown";
    final d = Duration(seconds: totalSeconds);
    return d.inHours > 0
        ? "${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}"
        : "${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  static void showDetailDialog(
      BuildContext context, FeedItem item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0A0E17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(item.thumbnailUrl ?? '',
                    height: 220, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _tag(item.type),
                        if (item.duration != null) ...[
                          const SizedBox(width: 15),
                          const Icon(Icons.timer_outlined,
                              color: Colors.white54, size: 16),
                          const SizedBox(width: 4),
                          Text(_formatDuration(item.duration),
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(item.description,
                        style: const TextStyle(
                            color: Colors.white70, height: 1.6, fontSize: 14)),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        // GOLD BUTTON -> NOW WATCH TRAILER
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (item.trailerUrl != null &&
                                  item.trailerUrl!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TrailerPlayerScreen(
                                        videoUrl: item.trailerUrl!),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Trailer not available for this item")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCFB56C),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text("WATCH TRAILER",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // OUTLINED BUTTON -> STILL CLOSE
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text("CLOSE"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCFB56C).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(4)),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: Color(0xFFCFB56C),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}
