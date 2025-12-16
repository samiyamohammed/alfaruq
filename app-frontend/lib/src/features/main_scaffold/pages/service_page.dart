import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:al_faruk_app/src/features/service/pages/donation_page.dart';
import 'package:al_faruk_app/src/features/service/pages/event_tickets_page.dart';
import 'package:al_faruk_app/src/features/service/pages/youtube_partners_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServicePage extends ConsumerStatefulWidget {
  const ServicePage({super.key});

  @override
  ConsumerState<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends ConsumerState<ServicePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 2. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.service, // Localized Title
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () {
          ref.read(bottomNavIndexProvider.notifier).state = 0;
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ServiceTile(
            icon: Icons.volunteer_activism,
            title: l10n.donation, // Localized
            subtitle: l10n.supportCauses, // Localized
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DonationPage())),
          ),
          const SizedBox(height: 16),
          _ServiceTile(
            icon: Icons.shopping_bag,
            title: l10n.halalGebeya, // Localized
            subtitle: l10n.islamicMarketplace, // Localized
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoon))); // Localized
            },
          ),
          const SizedBox(height: 16),
          _ServiceTile(
            icon: Icons.confirmation_number,
            title: l10n.eventTickets, // Localized
            subtitle: l10n.bookEvents, // Localized
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EventTicketsPage())),
          ),
          const SizedBox(height: 16),
          _ServiceTile(
            icon: Icons.video_library,
            title: l10n.ourYoutubePartners, // Localized
            subtitle: l10n.connectCreators, // Localized
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const YoutubePartnersPage())),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151E32),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: const Color(0xFFCFB56C), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
