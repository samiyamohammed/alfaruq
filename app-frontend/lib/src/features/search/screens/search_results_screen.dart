import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/core/models/news_item_model.dart';
import 'package:al_faruk_app/src/core/models/quran_models.dart';
import 'package:al_faruk_app/src/core/models/youtube_video_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
// --- IMPORTS FOR ROUTING ---
import 'package:al_faruk_app/src/features/main_scaffold/pages/book_detail_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/news_feed_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/sheikh_detail_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/youtube_content_player.dart';
import 'package:al_faruk_app/src/features/search/data/search_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filter State
  String _selectedFilterCode = 'all';

  // Map Display Name -> API Code
  final Map<String, String> _filters = {
    'All': 'all',
    'Books': 'BOOK',
    'Movies': 'MOVIE',
    'Series': 'SERIES',
    'Videos': 'youtube',
    'News': 'news',
    'Quran': 'quran',
  };

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Languages for correct Reciter Navigation (Prevents 400 Error)
    final languagesAsync = ref.watch(quranLanguagesProvider);
    final defaultLanguageId = languagesAsync.valueOrNull?.firstOrNull?.id;

    // Watch Search Provider
    final searchAsync = ref.watch(searchProvider(SearchArguments(
      query: widget.query,
      type: _selectedFilterCode,
    )));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      appBar: CustomAppBar(
        isSubPage: true,
        title: "Results for \"${widget.query}\"",
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // --- FILTER CHIPS ---
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = _filters.entries.elementAt(index);
                final label = entry.key;
                final code = entry.value;
                final isSelected = _selectedFilterCode == code;

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: const Color(0xFFCFB56C),
                  backgroundColor: const Color(0xFF151E32),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          isSelected ? const Color(0xFFCFB56C) : Colors.white24,
                    ),
                  ),
                  showCheckmark: false,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilterCode = code;
                      });
                    }
                  },
                );
              },
            ),
          ),

          // --- RESULTS BODY ---
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFCFB56C)),
              ),
              error: (err, stack) => const Center(
                child: Text(
                  "Search failed. Please try again.",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          "No results found for \"${widget.query}\"",
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Content (Books, Movies, etc.)
                    if (data.content.isNotEmpty) ...[
                      _buildSectionTitle("Library & Content"),
                      _buildContentGrid(context, data.content),
                      const SizedBox(height: 24),
                    ],

                    // 2. YouTube
                    if (data.youtube.isNotEmpty) ...[
                      _buildSectionTitle("Videos"),
                      _buildYoutubeList(context, data.youtube),
                      const SizedBox(height: 24),
                    ],

                    // 3. Reciters
                    if (data.reciters.isNotEmpty) ...[
                      _buildSectionTitle("Quran Reciters"),
                      _buildRecitersList(
                          context, data.reciters, defaultLanguageId),
                      const SizedBox(height: 24),
                    ],

                    // 4. News
                    if (data.news.isNotEmpty) ...[
                      _buildSectionTitle("News & Articles"),
                      _buildNewsList(context, data.news),
                      const SizedBox(height: 24),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFCFB56C),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- 1. CONTENT GRID ---
  Widget _buildContentGrid(BuildContext context, List<FeedItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            if (item.type == 'BOOK') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailScreen(book: item)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContentPlayerScreen(contentId: item.id),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.thumbnailUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Container(color: Colors.grey[900]),
                      ),
                      if (item.isLocked)
                        Container(
                          color: Colors.black54,
                          child: const Icon(Icons.lock,
                              color: Color(0xFFCFB56C), size: 20),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (item.type).replaceAll('_', ' '),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. YOUTUBE LIST ---
  Widget _buildYoutubeList(BuildContext context, List<YoutubeVideo> videos) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final video = videos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YoutubeContentPlayer(video: video),
              ),
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  video.thumbnailUrl,
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
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelTitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
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

  // --- 3. RECITERS LIST (FIXED NAVIGATION) ---
  Widget _buildRecitersList(BuildContext context, List<QuranReciter> reciters,
      String? defaultLangId) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reciters.length,
        separatorBuilder: (c, i) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final reciter = reciters[index];
          return GestureDetector(
            onTap: () {
              // Only navigate if we have a valid Language ID
              if (defaultLangId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SheikhDetailScreen(
                      reciter: reciter,
                      languageId: defaultLangId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Loading languages... please wait."),
                    backgroundColor: Color(0xFFCFB56C),
                  ),
                );
              }
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(reciter.imageUrl ?? ''),
                  backgroundColor: const Color(0xFF151E32),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    reciter.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 4. NEWS LIST ---
  Widget _buildNewsList(BuildContext context, List<NewsItem> news) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: news.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = news[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewsFeedScreen(initialNewsId: item.id),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.thumbnailUrl ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(width: 50, height: 50, color: Colors.grey),
                ),
              ),
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }
}
