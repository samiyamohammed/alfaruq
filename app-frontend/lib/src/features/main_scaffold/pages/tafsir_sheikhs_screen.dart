import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/quran_models.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/sheikh_detail_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TafsirSheikhsScreen extends ConsumerStatefulWidget {
  final String? initialLanguageId;

  const TafsirSheikhsScreen({super.key, this.initialLanguageId});

  @override
  ConsumerState<TafsirSheikhsScreen> createState() =>
      _TafsirSheikhsScreenState();
}

class _TafsirSheikhsScreenState extends ConsumerState<TafsirSheikhsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedLanguageId;

  @override
  void initState() {
    super.initState();
    if (widget.initialLanguageId != 'all') {
      _selectedLanguageId = widget.initialLanguageId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languagesAsync = ref.watch(quranLanguagesProvider);
    final bookmarkedIds = ref.watch(bookmarksProvider).value ?? {};

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.quranTafseer,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: languagesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (e, s) => Center(
            child: Text("${l10n.error}: $e",
                style: const TextStyle(color: Colors.white))),
        data: (languages) {
          if (languages.isEmpty)
            return Center(
                child: Text(l10n.noSheikhsFound,
                    style: const TextStyle(color: Colors.white)));

          final currentLanguageId = _selectedLanguageId ??
              (languages.isNotEmpty ? languages.first.id : null);

          return Column(
            children: [
              if (languages.isNotEmpty)
                _buildLanguageSelector(languages, currentLanguageId!),
              Expanded(
                  child: currentLanguageId != null
                      ? _buildSheikhsList(
                          currentLanguageId, l10n, bookmarkedIds)
                      : const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelector(
      List<QuranLanguage> languages, String currentId) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: languages.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = currentId == lang.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedLanguageId = lang.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFCFB56C)
                    : const Color(0xFF151E32),
                borderRadius: BorderRadius.circular(25),
                border: isSelected ? null : Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Text(lang.name,
                    style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheikhsList(
      String languageId, AppLocalizations l10n, Set<String> bookmarkedIds) {
    final recitersAsync = ref.watch(quranRecitersProvider(languageId));

    return recitersAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
      error: (e, s) => Center(
          child: Text("${l10n.error}: $e",
              style: const TextStyle(color: Colors.white))),
      data: (reciters) {
        if (reciters.isEmpty)
          return Center(
              child: Text(l10n.noSheikhsFound,
                  style: const TextStyle(color: Colors.white54)));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reciters.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sheikh = reciters[index];
            final bool isFav = bookmarkedIds.contains(sheikh.id);

            return InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SheikhDetailScreen(
                          reciter: sheikh, languageId: languageId))),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF151E32),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFCFB56C).withOpacity(0.3),
                              width: 2)),
                      child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(sheikh.imageUrl ?? ''),
                          backgroundColor: Colors.grey[900]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sheikh.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("114 ${l10n.surahsAvailable}",
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(bookmarksProvider.notifier)
                          .toggleReciterBookmark(sheikh),
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white24, size: 22),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white24, size: 14),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
