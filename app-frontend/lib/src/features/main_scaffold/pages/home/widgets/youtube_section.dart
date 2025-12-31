import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/youtube_video_model.dart'; // Ensure this import is correct for your model
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/youtube_channels_screen_videos.dart';
import 'package:al_faruk_app/src/features/player/screens/youtube_content_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YoutubeSection extends ConsumerWidget {
  const YoutubeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final youtubeAsync = ref.watch(youtubeContentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with See All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.popularVideos,
                style: const TextStyle(
                  color: Color(0xFFCFB56C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to the Grid of Popular Videos (The Tabbed Screen)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const YoutubeChannelsScreenVideos(),
                    ),
                  );
                },
                child: const Text(
                  "See All",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 220,
          child: youtubeAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFCFB56C)),
            ),
            error: (err, stack) => const Center(
              child: Text(
                'Error loading videos',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            data: (allVideos) {
              if (allVideos.isEmpty) return const SizedBox.shrink();

              // --- LOGIC TO GET 5 VIDEOS PER CHANNEL ---
              final List<YoutubeVideo> filteredVideos = [];
              final Map<String, int> channelCountMap = {};

              for (var video in allVideos) {
                final channelName = video.channelTitle;
                final currentCount = channelCountMap[channelName] ?? 0;

                // Only add the video if we have less than 5 for this specific channel
                if (currentCount < 5) {
                  filteredVideos.add(video);
                  channelCountMap[channelName] = currentCount + 1;
                }
              }

              // Use the filtered list for the horizontal scroll
              final videos = filteredVideos;

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
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
                    child: SizedBox(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 135,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFF151E32),
                                  image: DecorationImage(
                                    image: NetworkImage(video.thumbnailUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.channelTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
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
        ),
      ],
    );
  }
}
