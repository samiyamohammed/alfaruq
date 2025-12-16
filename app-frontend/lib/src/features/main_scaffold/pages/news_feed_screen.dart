import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/core/models/news_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart'; // 2. Import CustomAppBar
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart'; // 3. Import CustomDrawer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NewsFeedScreen extends ConsumerStatefulWidget {
  final String? initialNewsId;
  const NewsFeedScreen({super.key, this.initialNewsId});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  // 4. Create Key for Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _scrollController = ScrollController();
  bool _hasScrolled = false;

  void _scrollToIndex(int index) {
    if (_hasScrolled) return;
    _hasScrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          index * 500.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    // 5. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey, // Assign Key
      backgroundColor: const Color(0xFF0B101D),

      // 6. Add Drawer
      endDrawer: const CustomDrawer(),

      // 7. Use CustomAppBar
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.alfarukKheber, // Localized Title
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),

      body: newsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (err, stack) => Center(
            child: Text("${l10n.error}: $err", // Localized Error
                style: const TextStyle(color: Colors.white))),
        data: (newsList) {
          if (widget.initialNewsId != null) {
            final index =
                newsList.indexWhere((n) => n.id == widget.initialNewsId);
            if (index != -1) _scrollToIndex(index);
          }

          if (newsList.isEmpty) {
            return Center(
              child: Text(l10n.noContent, // Localized
                  style: const TextStyle(color: Colors.white54)),
            );
          }

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            separatorBuilder: (c, i) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              return _NewsCard(news: newsList[index], l10n: l10n);
            },
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  final NewsItem news;
  final AppLocalizations l10n; // Pass localization down
  const _NewsCard({required this.news, required this.l10n});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.news.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(widget.news.createdAt!)
        : "";

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  widget.news.thumbnailUrl ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(height: 200, color: Colors.grey[800]),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFB56C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.news.category,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCFB56C)),
                    ),
                    child: const Icon(Icons.mosque,
                        color: Color(0xFFCFB56C), size: 20),
                  ),
                ),
              ),
            ],
          ),

          // 2. Content Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.news.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Text(
                      widget.news.author,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text("•", style: TextStyle(color: Colors.white54)),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  widget.news.description,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Read More Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        _isExpanded
                            ? widget.l10n.readLess
                            : widget.l10n.readMore, // Localized
                        style: const TextStyle(
                          color: Color(0xFFCFB56C),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFFCFB56C),
                        size: 20,
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
