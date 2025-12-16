import 'dart:async';
import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/trailer_player_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:flutter/material.dart';

class FeaturedCarousel extends StatefulWidget {
  final List<FeedItem> items;
  const FeaturedCarousel({super.key, required this.items});

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentRealIndex = 0;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.items.length * 1000;
    _pageController =
        PageController(viewportFraction: 1.0, initialPage: initialPage);
    _currentRealIndex = initialPage % widget.items.length;

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
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
    // 2. Initialize Localization
    final l10n = AppLocalizations.of(context)!;
    final currentItem = widget.items[_currentRealIndex];

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _currentRealIndex = index % widget.items.length;
              });
            },
            itemBuilder: (context, index) {
              final int actualIndex = index % widget.items.length;
              final item = widget.items[actualIndex];
              return _buildCarouselItem(item);
            },
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Icons.info_outline, l10n.detail, () {
                // Localized
                HomePageStateHelper.showDetailDialog(
                    context, currentItem, l10n);
              }),
              SizedBox(
                width: 180,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ContentPlayerScreen(contentId: currentItem.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: Text(l10n.watchNow), // Localized
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCFB56C),
                    foregroundColor: Colors.black,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              _actionButton(Icons.add, l10n.addList, () {}), // Localized
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentRealIndex == index ? 24 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: _currentRealIndex == index
                    ? const Color(0xFFCFB56C)
                    : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(FeedItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(item.thumbnailUrl ?? ''),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.price != null && item.price != "0.00") ...[
                      Text(
                        "${double.tryParse(item.price!)?.toStringAsFixed(0)} ETB",
                        style: const TextStyle(
                          color: Color(0xFFCFB56C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("Amharic",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white70))
        ],
      ),
    );
  }
}

class HomePageStateHelper {
  static String _formatDuration(int? totalSeconds) {
    if (totalSeconds == null) return "Unknown";
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  static void showDetailDialog(
      BuildContext context, FeedItem item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF151E32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.movieDetails, // Localized
                    style: const TextStyle(
                        color: Color(0xFFCFB56C),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1, color: Colors.white24),

              // --- FIX: Added Spacing Here ---
              const SizedBox(height: 16),

              if (item.thumbnailUrl != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: NetworkImage(item.thumbnailUrl!),
                        fit: BoxFit.contain),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(item.type,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                        ),
                        if (item.duration != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time,
                              color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(_formatDuration(item.duration),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(item.description,
                        style: const TextStyle(
                            color: Colors.white70, height: 1.5)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ContentPlayerScreen(
                                          contentId: item.id)));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCFB56C),
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(
                                (item.price != null && item.price != "0.00")
                                    ? "${l10n.watchNow} ${double.tryParse(item.price!)?.toStringAsFixed(0)} ETB" // Localized
                                    : l10n.watchFree, // Localized
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (item.trailerUrl != null &&
                                  item.trailerUrl!.isNotEmpty) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => TrailerPlayerScreen(
                                            videoUrl: item.trailerUrl!)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(l10n
                                            .trailerNotAvailable), // Localized
                                        backgroundColor: Colors.redAccent));
                              }
                            },
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white70),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(
                                l10n.watchTrailer.toUpperCase()), // Localized
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
}
