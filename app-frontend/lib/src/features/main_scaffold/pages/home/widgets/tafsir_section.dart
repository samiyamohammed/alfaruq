import 'dart:async';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/sheikh_detail_screen.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TafsirSection extends ConsumerStatefulWidget {
  final List<FeedItem> items;
  final void Function(String selectedLanguageId)? onSeeAll;

  const TafsirSection({
    super.key,
    required this.items,
    this.onSeeAll,
  });

  @override
  ConsumerState<TafsirSection> createState() => _TafsirSectionState();
}

class _TafsirSectionState extends ConsumerState<TafsirSection> {
  String? _selectedLanguageId;
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
        const double slideDistance = 156.0;

        double targetScroll = currentScroll + slideDistance;

        if (targetScroll >= maxScroll + 10) {
          _scrollController.animateTo(
            0,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
        } else {
          _scrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
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
    final l10n = AppLocalizations.of(context)!;
    final languagesAsync = ref.watch(quranLanguagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. HEADER ---
        // Added top padding to separate from previous section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            l10n.quranTafseer,
            style: const TextStyle(
              color: Color(0xFFCFB56C),
              fontSize: 20, // Slightly larger for better hierarchy
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // --- 2. Language Filters & Content ---
        languagesAsync.when(
          loading: () => const SizedBox(height: 40),
          error: (e, s) => const SizedBox.shrink(),
          data: (languages) {
            if (languages.isEmpty) return const SizedBox.shrink();

            // Default to first language
            if (_selectedLanguageId == null) {
              Future.microtask(() {
                if (mounted)
                  setState(() => _selectedLanguageId = languages.first.id);
              });
            }
            final currentId = _selectedLanguageId ?? languages.first.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // A. Chips List
                SizedBox(
                  height: 36, // Compact height
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: languages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final isSelected = currentId == lang.id;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedLanguageId = lang.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFCFB56C)
                                : const Color(0xFF151E32),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFCFB56C)
                                  : Colors.white12,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            lang.name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // B. "See All" Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
                  child: GestureDetector(
                    onTap: () => widget.onSeeAll?.call(currentId),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "See All",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios,
                            size: 10, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                // C. Reciters Content
                _buildRecitersList(currentId),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecitersList(String languageId) {
    final recitersAsync = ref.watch(quranRecitersProvider(languageId));

    return SizedBox(
      height: 180,
      child: recitersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (e, s) => const SizedBox.shrink(),
        data: (reciters) {
          if (reciters.isEmpty) {
            return const Center(
                child: Text("No content available",
                    style: TextStyle(color: Colors.white24)));
          }

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: reciters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = reciters[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SheikhDetailScreen(
                        reciter: item,
                        languageId: languageId,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl ?? ''),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    ),
                    color: const Color(0xFF151E32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Gradient Overlay for Text Readability
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
                                Colors.black.withOpacity(0.8),
                                Colors.black
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Reciter Name
                      Positioned(
                        bottom: 12,
                        left: 8,
                        right: 8,
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
