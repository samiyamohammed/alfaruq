import 'dart:async';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/quran_models.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audio_session/audio_session.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/iqra_library_screen.dart';

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
    _initAudioSession();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final structureAsync = ref.watch(quranStructureProvider);

    String effectiveLanguageId = widget.languageId;
    if (effectiveLanguageId == 'all') {
      final languages = ref.watch(quranLanguagesProvider).valueOrNull;
      if (languages != null && languages.isNotEmpty) {
        effectiveLanguageId = languages.first.id;
      }
    }

    final String providerKey = "${widget.reciter.id}|$effectiveLanguageId";
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
              final Map<int, QuranRecitation> recitationMap = {};
              final List<QuranRecitation> allRecitations = [];
              for (var item in contentItems) {
                if (item.recitations.isNotEmpty) {
                  recitationMap[item.surah.id] = item.recitations.first;
                  allRecitations.add(item.recitations.first);
                }
              }

              if (contentItems.isEmpty) {
                return Center(
                    child: Text(l10n.noSheikhsFound,
                        style: const TextStyle(color: Colors.white54)));
              }

              final List<Widget> listWidgets = [];

              for (var juz in juzList) {
                final filteredSurahs = juz.surahs.where((surah) {
                  if (!recitationMap.containsKey(surah.id)) return false;
                  if (_searchQuery.isEmpty) return true;
                  return surah.name.toLowerCase().contains(_searchQuery) ||
                      surah.id.toString().contains(_searchQuery);
                }).toList();

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
                      child: _SurahPlayerCard(
                        surah: surah,
                        recitation: recitationMap[surah.id]!,
                        reciter: widget.reciter,
                        allRecitations: allRecitations,
                        languageId: effectiveLanguageId,
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

class _SurahPlayerCard extends ConsumerWidget {
  final QuranSurah surah;
  final QuranRecitation recitation;
  final QuranReciter reciter;
  final List<QuranRecitation> allRecitations;
  final String languageId;
  final AppLocalizations l10n;

  const _SurahPlayerCard({
    required this.surah,
    required this.recitation,
    required this.reciter,
    required this.allRecitations,
    required this.languageId,
    required this.l10n,
  });

  Future<void> _handlePlay(
      WidgetRef ref, AudioPlayer player, String? currentId) async {
    final bool isActive = currentId == recitation.id;
    if (isActive) {
      player.playing ? await player.pause() : await player.play();
    } else {
      await player.stop();

      // Load all surahs as a playlist to enable system Next/Prev controls
      final playlist = ConcatenatingAudioSource(
        children: allRecitations
            .map((r) => AudioSource.uri(
                  Uri.parse(r.audioUrl),
                  tag: MediaItem(
                    id: r.id,
                    album: "Quran Tafsir",
                    title: r.title,
                    artist: reciter.name,
                    artUri: Uri.parse(reciter.imageUrl ?? ''),
                    extras: {
                      'type': 'sheikh',
                      'reciterId': reciter.id,
                      'languageId': languageId
                    },
                  ),
                ))
            .toList(),
      );

      int startIndex = allRecitations.indexWhere((r) => r.id == recitation.id);
      await player.setAudioSource(playlist,
          initialIndex: startIndex >= 0 ? startIndex : 0);
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(globalAudioPlayerProvider);
    final isFav =
        (ref.watch(bookmarksProvider).value ?? {}).contains(recitation.id);

    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, snapshot) {
        final currentMediaItem =
            snapshot.data?.currentSource?.tag as MediaItem?;
        final bool isThisPlaying = currentMediaItem?.id == recitation.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF151E32),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isThisPlaying
                    ? const Color(0xFFCFB56C)
                    : Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(reciter.imageUrl ?? '',
                          width: 60, height: 85, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recitation.title,
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(reciter.name,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 12),
                          if (isThisPlaying)
                            StreamBuilder<Duration?>(
                              stream: player.positionStream,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                final duration =
                                    player.duration ?? Duration.zero;
                                return ProgressBar(
                                  progress: position,
                                  total: duration,
                                  buffered: player.bufferedPosition,
                                  onSeek: player.seek,
                                  barHeight: 4,
                                  baseBarColor: Colors.white10,
                                  progressBarColor: const Color(0xFFCFB56C),
                                  thumbColor: const Color(0xFFCFB56C),
                                  thumbRadius: 6,
                                  timeLabelTextStyle: const TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                );
                              },
                            )
                          else
                            const SizedBox(
                                height: 20,
                                child: Divider(color: Colors.white10)),
                        ],
                      ),
                    ),
                    // Favorite button inside the tile
                    IconButton(
                      onPressed: () => ref
                          .read(bookmarksProvider.notifier)
                          .toggleTafsirBookmark(recitation),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white38,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpeedButton(player, isThisPlaying),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10,
                              color: Colors.white70),
                          onPressed: isThisPlaying
                              ? () => player.seek(Duration(
                                  seconds: player.position.inSeconds - 10))
                              : null,
                        ),
                        StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final playing = playerState?.playing ?? false;
                            final processing = playerState?.processingState;

                            bool showPause = isThisPlaying && playing;
                            bool isLoading = isThisPlaying &&
                                (processing == ProcessingState.loading ||
                                    processing == ProcessingState.buffering);

                            if (isLoading) {
                              return const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFCFB56C))));
                            }

                            return IconButton(
                              iconSize: 48,
                              icon: Icon(
                                  showPause
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: const Color(0xFFCFB56C)),
                              onPressed: () => _handlePlay(
                                  ref, player, currentMediaItem?.id),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10,
                              color: Colors.white70),
                          onPressed: isThisPlaying
                              ? () => player.seek(Duration(
                                  seconds: player.position.inSeconds + 10))
                              : null,
                        ),
                      ],
                    ),
                    // Surah Number badge
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text("#${surah.id}",
                            style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedButton(AudioPlayer player, bool isActive) {
    return StreamBuilder<double>(
        stream: player.speedStream,
        builder: (context, snapshot) {
          final speed = snapshot.data ?? 1.0;
          return GestureDetector(
            onTap: isActive
                ? () {
                    double newSpeed = speed + 0.25;
                    if (newSpeed > 2.0) newSpeed = 1.0;
                    player.setSpeed(newSpeed);
                    HapticFeedback.selectionClick();
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4)),
              child: Text("${speed}x",
                  style: TextStyle(
                      color:
                          isActive ? const Color(0xFFCFB56C) : Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          );
        });
  }
}
