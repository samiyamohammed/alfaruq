import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/youtube_channels_screen.dart'; // IMPORT THIS
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChannelsSection extends StatelessWidget {
  const ChannelsSection({super.key});

  static const List<Map<String, String>> _channels = [
    {
      "name": "Al-Faruk Quran",
      "url": "https://youtube.com/@alfaruqquran?si=pXaFnH2hmFbulGNJ",
      "image": "assets/images/alfaruk_quran.jpg",
    },
    {
      "name": "Al-Faruk Maerifa",
      "url": "https://youtube.com/@almarifa.alfaruk1?si=tf4qQV1QzxQFaVKD",
      "image": "assets/images/alfaruk_maerifa.jpg",
    },
    {
      "name": "Al-Faruk Films",
      "url": "https://youtube.com/@alfarukfilms?si=IqIZ8RwSaQB1UOBn",
      "image": "assets/images/alfaruk_films.jpg",
    },
    {
      "name": "Al-Faruk Talk Show",
      "url": "https://youtube.com/@alfaruk-talkshow?si=sUUPXrt9Js1rdK-Y",
      "image": "assets/images/alfaruk_talkshow.jpg",
    },
  ];

  Future<void> _launchChannel(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open YouTube: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Updated Header with See All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                  l10n.ourChannels,
                style: const TextStyle(
                  color: Color(0xFFCFB56C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const YoutubeChannelsScreen()));
                },
                child: const Text("See All",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _channels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final channel = _channels[index];
              return GestureDetector(
                onTap: () => _launchChannel(context, channel['url']!),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151E32),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                        image: DecorationImage(
                          image: AssetImage(channel['image']!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white24, size: 30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        channel['name']!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
