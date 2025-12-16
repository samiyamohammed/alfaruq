import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart'; // 2. Import CustomAppBar
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart'; // 3. Import CustomDrawer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class YoutubePartnersPage extends ConsumerStatefulWidget {
  const YoutubePartnersPage({super.key});

  @override
  ConsumerState<YoutubePartnersPage> createState() =>
      _YoutubePartnersPageState();
}

class _YoutubePartnersPageState extends ConsumerState<YoutubePartnersPage> {
  // 4. Create Key for Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Helper to open the URL
  Future<void> _launchChannel(BuildContext context, String urlString) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.couldNotLaunch)), // Localized Error
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.error}: $e")), // Localized Error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 5. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    // Define Data
    final List<Map<String, String>> partners = [
      {
        "name": "Muaz Habib",
        "image": "assets/images/muaz.jpg",
        "url": "https://www.youtube.com/@MuazHabibofficial"
      },
      {
        "name": "Esam Ahmed",
        "image": "assets/images/esam.jpg",
        "url": "https://www.youtube.com/@Esam_Ahmed_Official"
      },
      {
        "name": "Warida",
        "image": "assets/images/warida.jpg",
        "url": "https://www.youtube.com/@WaridaIslamicArtGroup"
      },
      {
        "name": "Abduselam Abera",
        "image": "assets/images/abduselam.jpg",
        "url": "https://www.youtube.com/@abduabera"
      },
      {
        "name": "Fuad Shemsu",
        "image": "assets/images/fuad.jpg",
        "url": "https://www.youtube.com/@fuadshemsuofficial9637"
      },
      {
        "name": "Amir Hussen",
        "image": "assets/images/amir hussein.jpg",
        "url": "https://www.youtube.com/@AMIRHUSSENofficial"
      },
      {
        "name": "Selhadin Hussen",
        "image": "assets/images/selehadin.jpg",
        "url": "https://www.youtube.com/@SelehadinHussenofficial"
      },
      {
        "name": "Sualih Astatke",
        "image": "assets/images/sualih.jpg",
        "url": "https://www.youtube.com/@sualih.astatke"
      },
      {
        "name": "Inaya Records",
        "image": "assets/images/inaya.jpg",
        "url": "https://www.youtube.com/@iNayaRecords"
      },
      {
        "name": "Sualih Muhammed",
        "image": "assets/images/sualih mohammed.jpg",
        "url": "https://www.youtube.com/@SualihMohammedOfficial"
      },
      {
        "name": "Zaeferan",
        "image": "assets/images/zaeferan.jpg",
        "url": "https://www.youtube.com/@zaeferarecords"
      },
    ];

    return Scaffold(
      key: _scaffoldKey, // Assign Key
      backgroundColor: const Color(0xFF0B101D),

      // 6. Add Drawer
      endDrawer: const CustomDrawer(),

      // 7. Use CustomAppBar
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.ourYoutubePartners, // Localized Title
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: partners.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final partner = partners[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // Image Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                    image: DecorationImage(
                      image: AssetImage(partner["image"]!),
                      fit: BoxFit.cover,
                      // Handle missing assets gracefully
                      onError: (exception, stackTrace) {},
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    partner["name"]!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _launchChannel(context, partner["url"]!),
                  icon: const Icon(Icons.play_circle_outline,
                      color: Colors.black, size: 16),
                  label: Text(l10n.subscribe), // Localized "Subscribe"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCFB56C),
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
