import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/common/screens/guest_restricted_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- UPDATED PROVIDER ---
final myPurchasesProvider =
    FutureProvider.autoDispose<List<FeedItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    // FIX 1: Reduced limit to 20 to avoid "400 Bad Request" from server
    final response = await dio.get('/feed/my-purchases', queryParameters: {
      'page': 1,
      'limit': 20,
    });

    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      final List<FeedItem> validItems = [];

      for (var json in data) {
        try {
          validItems.add(FeedItem.fromJson(json));
        } catch (e) {
          debugPrint("⚠️ Skipping invalid item: ${json['title']} - Error: $e");
        }
      }
      return validItems;
    }
    return [];
  } catch (e) {
    if (e is DioException) {
      // Pass the DioException through so we can read the status code/message in UI
      throw e;
    }
    throw e;
  }
});

class YeneMoviesPage extends ConsumerStatefulWidget {
  const YeneMoviesPage({super.key});

  @override
  ConsumerState<YeneMoviesPage> createState() => _YeneMoviesPageState();
}

class _YeneMoviesPageState extends ConsumerState<YeneMoviesPage> {
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final purchasesState = ref.watch(myPurchasesProvider);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const CustomDrawer(),
      backgroundColor: const Color(0xFF0B101D),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.yeneMovie,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () {
          ref.read(bottomNavIndexProvider.notifier).state = 0;
        },
      ),
      body: purchasesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFCFB56C)),
        ),
        error: (err, stack) {
          // 1. Handle Guest Access
          if (err is DioException && err.response?.statusCode == 403) {
            return const GuestRestrictedScreen();
          }

          // 2. Extract Server Error Message (for 400 Bad Request)
          String errorMsg = "Something went wrong";
          if (err is DioException && err.response?.data != null) {
            final data = err.response!.data;
            // Try to find the 'message' field in the error response
            if (data is Map && data['message'] != null) {
              errorMsg = data['message'].toString();
            } else if (data is String) {
              errorMsg = data;
            }
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    "Error Loading Purchases",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  // Display the specific server error
                  Text(
                    errorMsg,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Colors.redAccent[100], fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => ref.refresh(myPurchasesProvider),
                    icon: const Icon(Icons.refresh, color: Color(0xFFCFB56C)),
                    label: const Text("Retry",
                        style: TextStyle(color: Color(0xFFCFB56C))),
                  )
                ],
              ),
            ),
          );
        },
        data: (allPurchases) {
          // --- 1. MERGE MOVIES, SERIES, & DOCUMENTARIES ---
          final videoLibrary = allPurchases.where((i) {
            return ['MOVIE', 'SERIES', 'DOCUMENTARY'].contains(i.type);
          }).toList();

          // --- 2. NASHEEDS ---
          final nasheedsList = allPurchases.where((i) {
            return ['MUSIC_VIDEO', 'NASHEED'].contains(i.type);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.yourSavedMovies,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  l10n.swipeToSwitch,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              // --- TABS ---
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildTabButton(
                            l10n.navMovies, Icons.movie_outlined, 0)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTabButton(
                            l10n.nasheeds, Icons.music_note_outlined, 1)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTabButton(
                            l10n.favorites, Icons.star_border, 2)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- CONTENT PAGES ---
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _selectedIndex = index),
                  children: [
                    // TAB 0: Video Library
                    videoLibrary.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.local_movies_outlined,
                            message: l10n.noSavedMovies,
                            subMessage: l10n.addMoviesHint,
                            buttonLabel: l10n.browseContent,
                          )
                        : _buildContentGrid(videoLibrary),

                    // TAB 1: Nasheeds
                    nasheedsList.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.music_off_outlined,
                            message: l10n.noSavedNasheeds,
                            subMessage: l10n.addNasheedsHint,
                            buttonLabel: l10n.browseContent,
                          )
                        : _buildContentGrid(nasheedsList),

                    // TAB 2: Favorites
                    _buildEmptyState(
                      icon: Icons.star_border,
                      message: l10n.noFavoritesYet,
                      subMessage: l10n.markFavoritesHint,
                      buttonLabel: l10n.browseContent,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- GRID WIDGET ---
  Widget _buildContentGrid(List<FeedItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSeries = item.type == 'SERIES';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContentPlayerScreen(
                  contentId: item.id,
                  relatedContent: items,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(item.thumbnailUrl ?? ''),
                          fit: BoxFit.cover,
                        ),
                        color: Colors.grey[900],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black26,
                      ),
                    ),
                    Center(
                      child: item.isLocked
                          ? const Icon(Icons.lock,
                              color: Colors.white, size: 32)
                          : Icon(
                              isSeries
                                  ? Icons.playlist_play_rounded
                                  : Icons.play_circle_fill,
                              color: Colors.white70,
                              size: 40,
                            ),
                    ),
                    if (isSeries)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCFB56C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "SERIES",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                item.type.replaceAll('_', ' '),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCFB56C) : const Color(0xFF151E32),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.black : Colors.grey),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String message,
      required String subMessage,
      required String buttonLabel}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: const Color(0xFFCFB56C)),
        const SizedBox(height: 24),
        Text(message,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFB56C),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(buttonLabel,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
