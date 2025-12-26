import 'dart:async';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart'; // Added
import 'package:al_faruk_app/src/features/common/utils/guest_prompt.dart'; // Added
import 'package:al_faruk_app/src/features/main_scaffold/pages/sheikh_detail_screen.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final languagesAsync = ref.watch(quranLanguagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            l10n.quranTafseer,
            style: const TextStyle(
                color: Color(0xFFCFB56C),
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
        ),
        languagesAsync.when(
          loading: () => const SizedBox(height: 40),
          error: (e, s) => const SizedBox.shrink(),
          data: (languages) {
            if (languages.isEmpty) return const SizedBox.shrink();
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
                SizedBox(
                  height: 36,
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
                                    : Colors.white12),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
                  child: GestureDetector(
                    onTap: () => widget.onSeeAll?.call(currentId),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("See All",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios,
                            size: 10, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
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
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};

    return SizedBox(
      height: 180,
      child: recitersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (e, s) => const SizedBox.shrink(),
        data: (reciters) {
          if (reciters.isEmpty) return const SizedBox.shrink();

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: reciters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = reciters[index];
              final bool isFav = bookmarkedIds.contains(item.id);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SheikhDetailScreen(
                              reciter: item, languageId: languageId)));
                },
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                        image: NetworkImage(item.imageUrl ?? ''),
                        fit: BoxFit.cover),
                    color: const Color(0xFF151E32),
                  ),
                  child: Stack(
                    children: [
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
                                end: Alignment.bottomCenter),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () {
                            // CHECK AUTH STATUS
                            final authState = ref.read(authControllerProvider);
                            if (authState == AuthState.guest) {
                              GuestPrompt.show(context, ref);
                              return;
                            }
                            ref
                                .read(bookmarksProvider.notifier)
                                .toggleReciterBookmark(item);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.black45, shape: BoxShape.circle),
                            child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white,
                                size: 14),
                          ),
                        ),
                      ),
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
                              height: 1.2),
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
