import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/quran_models.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class SheikhDetailScreen extends ConsumerStatefulWidget {
  final QuranReciter reciter;
  final String languageId;

  const SheikhDetailScreen({
    super.key,
    required this.reciter,
    required this.languageId,
  });

  @override
  ConsumerState<SheikhDetailScreen> createState() => _SheikhDetailScreenState();
}

class _SheikhDetailScreenState extends ConsumerState<SheikhDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Listen to search input changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 1. Fetch Structure
    final structureAsync = ref.watch(quranStructureProvider);

    // 2. Fetch Recitations
    final String providerKey = "${widget.reciter.id}|${widget.languageId}";
    final contentAsync = ref.watch(reciterRecitationsProvider(providerKey));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: widget.reciter.name,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
        // Handle Search from AppBar
        onSearchChanged: (query) {
          setState(() {
            _searchQuery = query.trim().toLowerCase();
          });
        },
      ),
      body: structureAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (e, s) => Center(
            child: Text("Structure Error: $e",
                style: const TextStyle(color: Colors.white))),
        data: (juzList) {
          return contentAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
            error: (e, s) => Center(
                child: Text("Audio Error: $e",
                    style: const TextStyle(color: Colors.white))),
            data: (contentItems) {
              // 1. Map Data (Surah ID -> Recitation Object)
              final Map<int, QuranRecitation> recitationMap = {};
              for (var item in contentItems) {
                if (item.recitations.isNotEmpty) {
                  // We map the whole recitation object, not just the URL
                  recitationMap[item.surah.id] = item.recitations.first;
                }
              }

              if (contentItems.isEmpty) {
                return Center(
                    child: Text(l10n.noSheikhsFound,
                        style: const TextStyle(color: Colors.white54)));
              }

              // 2. Filter & Build List
              final List<Widget> listWidgets = [];

              for (var juz in juzList) {
                // Filter Surahs inside this Juz
                final filteredSurahs = juz.surahs.where((surah) {
                  // A. Must have audio available
                  if (!recitationMap.containsKey(surah.id)) return false;

                  // B. If search is empty, show all
                  if (_searchQuery.isEmpty) return true;

                  // C. Check Search Matches
                  final bool nameMatch =
                      surah.name.toLowerCase().contains(_searchQuery);
                  final bool juzMatch =
                      juz.name.toLowerCase().contains(_searchQuery);
                  final bool numberMatch =
                      surah.id.toString().contains(_searchQuery);

                  return nameMatch || juzMatch || numberMatch;
                }).toList();

                // Only add Juz header if it has visible content
                if (filteredSurahs.isNotEmpty) {
                  listWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16),
                      child: Text(
                        "${juz.name} (${filteredSurahs.length} ${l10n.surah}s)",
                        style: const TextStyle(
                            color: Color(0xFFCFB56C),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  );

                  for (var surah in filteredSurahs) {
                    listWidgets.add(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SurahTile(
                        surah: surah,
                        recitation:
                            recitationMap[surah.id]!, // Pass full object
                        l10n: l10n,
                      ),
                    ));
                  }

                  listWidgets.add(const SizedBox(height: 12));
                }
              }

              if (listWidgets.isEmpty) {
                return const Center(
                    child: Text("No matching Surahs found.",
                        style: TextStyle(color: Colors.white54)));
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: listWidgets,
              );
            },
          );
        },
      ),
    );
  }
}

class _SurahTile extends StatefulWidget {
  final QuranSurah surah;
  final QuranRecitation recitation; // Changed from audioUrl to full object
  final AppLocalizations l10n;

  const _SurahTile({
    required this.surah,
    required this.recitation,
    required this.l10n,
  });

  @override
  State<_SurahTile> createState() => _SurahTileState();
}

class _SurahTileState extends State<_SurahTile> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final url = widget.recitation.audioUrl;
    if (url.isEmpty) return;

    if (_controller == null) {
      setState(() => _isInitialized = false);
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      try {
        await _controller!.initialize();
        setState(() {
          _isInitialized = true;
          _duration = _controller!.value.duration;
        });
        _controller!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _controller!.value.isPlaying;
              _position = _controller!.value.position;
            });
          }
        });
        _controller!.play();
      } catch (e) {
        debugPrint("Audio Error: $e");
      }
    } else {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return "${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }
    return "${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32), // Dark Blue Card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // --- TOP PART: Player Control & Mini Info ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePlay,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFCFB56C),
                    child: (!_isInitialized && _controller != null)
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title from Recitation (e.g. "Al Baqarah")
                      Text(
                        widget.recitation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Duration / Status
                      Text(
                        _isInitialized
                            ? "${_formatDuration(_position)} / ${_formatDuration(_duration)}"
                            : widget.l10n.tapToPlay,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- PROGRESS BAR (If Playing) ---
          if (_isInitialized)
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFCFB56C),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.transparent,
              ),
              padding: EdgeInsets.zero,
            ),

          const Divider(height: 1, color: Colors.white10),

          // --- BOTTOM PART: Detailed Info ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Surah Name
                      Text(
                        widget.surah.name, // e.g. "Surah Al-Baqarah"
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Duration (Simulated or fetched)
                      Text(
                        _isInitialized
                            ? _formatDuration(_duration)
                            : "", // Placeholder until loaded
                        style: const TextStyle(
                          color: Color(0xFFCFB56C),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subtitle / Description
                      Text(
                        widget.recitation.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Surah Number Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "#${widget.surah.id}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
