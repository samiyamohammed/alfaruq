import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/core/models/quran_models.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/common/screens/guest_restricted_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/sheikh_detail_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteUIModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String type;
  final bool isLocked;
  final dynamic originalObject;
  final String? languageId;

  FavoriteUIModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.type,
    this.isLocked = false,
    required this.originalObject,
    this.languageId,
  });
}

final myPurchasesProvider =
    FutureProvider.autoDispose<List<FeedItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio
        .get('/feed/my-purchases', queryParameters: {'page': 1, 'limit': 50});
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.map((json) => FeedItem.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    rethrow;
  }
});

class YeneMoviesPage extends ConsumerStatefulWidget {
  const YeneMoviesPage({super.key});
  @override
  ConsumerState<YeneMoviesPage> createState() => _YeneMoviesPageState();
}

class _YeneMoviesPageState extends ConsumerState<YeneMoviesPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(myPurchasesProvider);
      ref.read(bookmarksProvider.notifier).fetchBookmarks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(myPurchasesProvider);
      ref.read(bookmarksProvider.notifier).fetchBookmarks();
    }
  }

  List<FeedItem> _flattenFeed(List<FeedItem> items) {
    List<FeedItem> flattened = [];
    for (var i in items) {
      flattened.add(i);
      if (i.children.isNotEmpty) flattened.addAll(_flattenFeed(i.children));
    }
    return flattened;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final purchasesState = ref.watch(myPurchasesProvider);
    final bookmarksState = ref.watch(bookmarksProvider);
    final topLevelFeed = ref.watch(feedContentProvider).value ?? [];
    final languages = ref.watch(quranLanguagesProvider).value ?? [];

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const CustomDrawer(),
      backgroundColor: const Color(0xFF0B101D),
      appBar: CustomAppBar(
          isSubPage: true,
          title: l10n.yeneMovie,
          scaffoldKey: _scaffoldKey,
          onLeadingPressed: () =>
              ref.read(bottomNavIndexProvider.notifier).state = 0),
      body: RefreshIndicator(
        color: const Color(0xFFCFB56C),
        onRefresh: () async {
          ref.refresh(myPurchasesProvider);
          return ref.read(bookmarksProvider.notifier).fetchBookmarks();
        },
        child: purchasesState.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
          // --- UPDATED ERROR HANDLING FOR GUESTS ---
          error: (err, stack) {
            // Check if the error is a 403 Forbidden (Guest user)
            if (err is DioException && err.response?.statusCode == 403) {
              return const GuestRestrictedScreen();
            }

            // Default Error View
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.error,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => ref.refresh(myPurchasesProvider),
                    child: const Text("Retry",
                        style: TextStyle(color: Color(0xFFCFB56C))),
                  )
                ],
              ),
            );
          },
          data: (allPurchases) {
            final movies = allPurchases
                .where(
                    (i) => ['MOVIE', 'SERIES', 'DOCUMENTARY'].contains(i.type))
                .toList();
            final nasheeds = allPurchases
                .where((i) => ['MUSIC_VIDEO', 'NASHEED'].contains(i.type))
                .toList();

            final favIds = bookmarksState.value ?? {};
            List<FavoriteUIModel> combinedFavs = [];

            // 1. Add Feed Items
            for (var item in _flattenFeed(topLevelFeed)) {
              if (favIds.contains(item.id)) {
                combinedFavs.add(FavoriteUIModel(
                    id: item.id,
                    title: item.title,
                    imageUrl: item.thumbnailUrl,
                    type: item.type,
                    isLocked: item.isLocked,
                    originalObject: item));
              }
            }

            // 2. Add Reciters & Recitations
            for (var lang in languages) {
              final reciters =
                  ref.watch(quranRecitersProvider(lang.id)).value ?? [];
              for (var r in reciters) {
                // Check Sheikhs
                if (favIds.contains(r.id) &&
                    !combinedFavs.any((x) => x.id == r.id)) {
                  combinedFavs.add(FavoriteUIModel(
                      id: r.id,
                      title: r.name,
                      imageUrl: r.imageUrl,
                      type: 'reciter',
                      originalObject: r,
                      languageId: lang.id));
                }

                // Check Individual Surahs (Tafsirs)
                final String recitationsKey = "${r.id}|${lang.id}";
                final recitationsItems = ref
                        .watch(reciterRecitationsProvider(recitationsKey))
                        .value ??
                    [];
                for (var rItem in recitationsItems) {
                  for (var rec in rItem.recitations) {
                    if (favIds.contains(rec.id) &&
                        !combinedFavs.any((x) => x.id == rec.id)) {
                      combinedFavs.add(FavoriteUIModel(
                          id: rec.id,
                          title: rec.title,
                          subtitle: r.name,
                          imageUrl: r.imageUrl,
                          type: 'tafsir',
                          originalObject: r,
                          languageId: lang.id));
                    }
                  }
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(l10n.yourSavedMovies,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14))),
                const SizedBox(height: 16),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                        child: _buildTabButton(
                            "Movies / Series", Icons.movie_filter_outlined, 0)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTabButton(
                            l10n.nasheeds, Icons.music_note_outlined, 1)),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            _buildTabButton(l10n.favorites, Icons.favorite, 2)),
                  ]),
                ),
                const SizedBox(height: 20),
                Expanded(
                    child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _selectedIndex = i),
                  children: [
                    movies.isEmpty
                        ? _buildEmptyState(Icons.movie, "No Movies",
                            l10n.addMoviesHint, l10n.browseContent)
                        : _buildContentGrid(movies
                            .map((m) => FavoriteUIModel(
                                id: m.id,
                                title: m.title,
                                imageUrl: m.thumbnailUrl,
                                type: m.type,
                                isLocked: m.isLocked,
                                originalObject: m))
                            .toList()),
                    nasheeds.isEmpty
                        ? _buildEmptyState(
                            Icons.music_note,
                            l10n.noSavedNasheeds,
                            l10n.addNasheedsHint,
                            l10n.browseContent)
                        : _buildContentGrid(nasheeds
                            .map((n) => FavoriteUIModel(
                                id: n.id,
                                title: n.title,
                                imageUrl: n.thumbnailUrl,
                                type: n.type,
                                isLocked: n.isLocked,
                                originalObject: n))
                            .toList()),
                    combinedFavs.isEmpty
                        ? _buildEmptyState(
                            Icons.favorite_border,
                            l10n.noFavoritesYet,
                            l10n.markFavoritesHint,
                            l10n.browseContent)
                        : _buildContentGrid(combinedFavs),
                  ],
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentGrid(List<FavoriteUIModel> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isAudio = item.type == 'reciter' || item.type == 'tafsir';

        return GestureDetector(
          onTap: () {
            if (isAudio) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SheikhDetailScreen(
                          reciter: item.originalObject,
                          languageId: item.languageId ?? 'all')));
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ContentPlayerScreen(contentId: item.id)));
            }
          },
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                      image: NetworkImage(item.imageUrl ?? ''),
                      fit: BoxFit.cover),
                  color: const Color(0xFF151E32)),
              child: Center(
                  child: item.isLocked
                      ? const Icon(Icons.lock, color: Colors.white, size: 32)
                      : Icon(isAudio ? Icons.mic : Icons.play_circle_fill,
                          color: Colors.white70, size: 40)),
            )),
            const SizedBox(height: 8),
            Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            if (item.subtitle != null)
              Text(item.subtitle!,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(item.type.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(color: Color(0xFFCFB56C), fontSize: 10)),
          ]),
        );
      },
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final bool isSel = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _pageController.animateToPage(index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      },
      child: Container(
        decoration: BoxDecoration(
            color: isSel ? const Color(0xFFCFB56C) : const Color(0xFF151E32),
            borderRadius: BorderRadius.circular(4)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: isSel ? Colors.black : Colors.grey),
          const SizedBox(width: 8),
          Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isSel ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg, String sub, String btn) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 60, color: const Color(0xFFCFB56C)),
      const SizedBox(height: 24),
      Text(msg,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(sub,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 32),
      ElevatedButton(
          onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 0,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFB56C),
              foregroundColor: Colors.black),
          child: Text(btn)),
      const SizedBox(height: 100),
    ]);
  }
}
