import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart'; // 2. Import CustomAppBar
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart'; // 3. Import CustomDrawer
import 'package:al_faruk_app/src/features/player/screens/youtube_content_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// Changed to ConsumerStatefulWidget to handle Key and Localization
class YoutubeChannelsScreen extends ConsumerStatefulWidget {
  const YoutubeChannelsScreen({super.key});

  @override
  ConsumerState<YoutubeChannelsScreen> createState() =>
      _YoutubeChannelsScreenState();
}

class _YoutubeChannelsScreenState extends ConsumerState<YoutubeChannelsScreen> {
  // 4. Create Key for Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _launchChannelUrl(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 5. Initialize Localization
    final l10n = AppLocalizations.of(context)!;
    final youtubeAsync = ref.watch(youtubeContentProvider);

    // 6. Define Channels List inside build to access l10n
    final List<Map<String, String>> channels = [
      {
        "name": "AL-FARUK QURAN / ...",
        "desc": l10n.descQuran, // Localized
        "url": "https://youtube.com/@alfaruqquran?si=pXaFnH2hmFbulGNJ",
        "image": "assets/images/alfaruk_quran.jpg",
      },
      {
        "name": "አል-ፋሩቅ አል-ማዕሪፋ / ...",
        "desc": l10n.descKnowledge, // Localized
        "url": "https://youtube.com/@almarifa.alfaruk1?si=tf4qQV1QzxQFaVKD",
        "image": "assets/images/alfaruk_maerifa.jpg",
      },
      {
        "name": "Al-Faruk Films",
        "desc": l10n.descMovies, // Localized
        "url": "https://youtube.com/@alfarukfilms?si=IqIZ8RwSaQB1UOBn",
        "image": "assets/images/alfaruk_films.jpg",
      },
      {
        "name": "አል-ፋሩቅ ቶክ ሾው / Al-...",
        "desc": l10n.descTalkShow, // Localized
        "url": "https://youtube.com/@alfaruk-talkshow?si=sUUPXrt9Js1rdK-Y",
        "image": "assets/images/alfaruk_talkshow.jpg",
      },
    ];

    return Scaffold(
      key: _scaffoldKey, // Assign Key
      backgroundColor: const Color(0xFF0B101D),

      // 7. Add Drawer
      endDrawer: const CustomDrawer(),

      // 8. Use CustomAppBar
      appBar: CustomAppBar(
        isSubPage: true,
        title:
            "Al-Faruk Channels", // Or use l10n.ourYoutubePartners if preferred
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.subscribeSubtitle, // Localized
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // --- 1. CHANNELS LIST ---
            Text(
              l10n.ourChannels, // Localized
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: channels.length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final channel = channels[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151E32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: AssetImage(channel['image']!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel['name']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFCFB56C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              channel['desc']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Subscribe Button
                      ElevatedButton(
                        onPressed: () =>
                            _launchChannelUrl(context, channel['url']!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: const Size(80, 36),
                        ),
                        child: Text(l10n.subscribe, // Localized
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // --- 2. POPULAR VIDEOS GRID ---
            Text(
              l10n.popularVideos, // Localized
              style: const TextStyle(
                  color: Color(0xFFCFB56C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            youtubeAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
              error: (err, stack) => Center(
                  child: Text("${l10n.error}: $err", // Localized
                      style: const TextStyle(color: Colors.white))),
              data: (videos) {
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: videos.length,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(video.thumbnailUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow,
                                      color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.channelTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
