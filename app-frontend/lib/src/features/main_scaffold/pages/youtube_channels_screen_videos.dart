import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:al_faruk_app/src/features/player/screens/youtube_content_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YoutubeChannelsScreenVideos extends ConsumerStatefulWidget {
  const YoutubeChannelsScreenVideos({super.key});

  @override
  ConsumerState<YoutubeChannelsScreenVideos> createState() =>
      _YoutubeChannelsScreenState();
}

class _YoutubeChannelsScreenState
    extends ConsumerState<YoutubeChannelsScreenVideos>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  final List<Map<String, String>> _channels = [
    {
      "label": "Quran",
      "id": "AL-FARUK QURAN / አል-ፋሩቅ ቁርአን",
    },
    {
      "label": "Ma'rifah",
      "id": "አል-ፋሩቅ አል-ማዕሪፋ / Al-FARUK AI-MARIFAH",
    },
    {
      "label": "Films",
      "id": "Al-Faruk Films",
    },
    {
      "label": "Multimedia",
      "id": "Al Faruk Multimedia Production",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _channels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: "Al-Faruk Channels",
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // --- BEAUTIFIED TAB BAR ---
          Container(
            color: const Color(0xFF0B101D),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),

              // Remove the default ugly divider line
              dividerColor: Colors.transparent,

              // Premium Indicator Styling
              indicatorSize:
                  TabBarIndicatorSize.label, // Line matches text width
              indicatorColor: const Color(0xFFCFB56C),
              indicatorWeight: 4, // Thicker line
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 4.0, color: Color(0xFFCFB56C)),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(4)), // Rounded tip
              ),

              // Text Styling
              labelColor: const Color(0xFFCFB56C),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, // Extra bold for selected
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0,
              ),

              // Ripple Effect Color
              overlayColor: MaterialStateProperty.all(
                const Color(0xFFCFB56C).withOpacity(0.1),
              ),

              tabs: _channels.map((c) {
                return Tab(
                  child: Container(
                    // Add vertical padding to center text nicely
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(c['label']!.toUpperCase()),
                  ),
                );
              }).toList(),
            ),
          ),

          // --- TAB CONTENT ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _channels.map((channel) {
                return _ChannelVideoList(channelName: channel['id']!);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelVideoList extends ConsumerWidget {
  final String channelName;

  const _ChannelVideoList({required this.channelName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(channelVideosProvider(channelName));

    return RefreshIndicator(
      color: const Color(0xFFCFB56C),
      backgroundColor: const Color(0xFF151E32),
      onRefresh: () async {
        return ref.refresh(channelVideosProvider(channelName));
      },
      child: videosAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Could not load videos.\nCheck your internet connection.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[300]),
            ),
          ),
        ),
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    const Icon(Icons.video_library_outlined,
                        size: 48, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      "No videos found for this channel.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final video = videos[index];

              String dateString = "";
              if (video.publishedAt != null) {
                final date = video.publishedAt!;
                dateString =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YoutubeContentPlayer(video: video),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151E32),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Area
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                video.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white54, width: 1.5),
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white, size: 30),
                          ),
                        ],
                      ),

                      // Video Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: const Color(0xFFCFB56C),
                                  child: Text(
                                    video.channelTitle.isNotEmpty
                                        ? video.channelTitle[0]
                                        : "A",
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    video.channelTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (dateString.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    dateString,
                                    style: const TextStyle(
                                        color: Colors.white24, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ],
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
