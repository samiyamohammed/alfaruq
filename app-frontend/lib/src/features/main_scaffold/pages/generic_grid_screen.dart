import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/trailer_player_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/prophet_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenericGridScreen extends ConsumerStatefulWidget {
  final String title;
  final List<FeedItem> items;

  const GenericGridScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  ConsumerState<GenericGridScreen> createState() => _GenericGridScreenState();
}

class _GenericGridScreenState extends ConsumerState<GenericGridScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: widget.title,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: widget.items.isEmpty
          ? Center(
              child: Text(
                l10n.noContent,
                style: const TextStyle(color: Colors.white54),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isFav = bookmarkedIds.contains(item.id);

                return _buildGridCard(context, item, l10n, isFav);
              },
            ),
    );
  }

  Widget _buildGridCard(
      BuildContext context, FeedItem item, AppLocalizations l10n, bool isFav) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToContent(context, item),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                      image: DecorationImage(
                        image: NetworkImage(item.thumbnailUrl ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Fav Icon Overlay
                  Positioned(
                    top: 8,
                    left: 8,
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
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Price Tag Overlay
                  if (item.price != null && item.price != '0.00')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFFCFB56C), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline,
                                color: Color(0xFFCFB56C), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              "${double.tryParse(item.price!)?.toStringAsFixed(0)} ETB",
                              style: const TextStyle(
                                color: Color(0xFFCFB56C),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: TextButton.icon(
              onPressed: () {
                if (item.trailerUrl != null && item.trailerUrl!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrailerPlayerScreen(videoUrl: item.trailerUrl!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.trailerNotAvailable)),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow_outlined,
                  color: Color(0xFFCFB56C), size: 18),
              label: Text(
                l10n.watchTrailer,
                style: const TextStyle(
                  color: Color(0xFFCFB56C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToContent(BuildContext context, FeedItem item) {
    if (item.type == 'PROPHET_HISTORY') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProphetHistoryScreen(contentId: item.id)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ContentPlayerScreen(
                    contentId: item.id,
                    relatedContent: widget.items,
                  )));
    }
  }
}
