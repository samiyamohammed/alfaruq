import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart'; // 2. Import CustomAppBar
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart'; // 3. Import CustomDrawer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventTicketsPage extends ConsumerStatefulWidget {
  const EventTicketsPage({super.key});

  @override
  ConsumerState<EventTicketsPage> createState() => _EventTicketsPageState();
}

class _EventTicketsPageState extends ConsumerState<EventTicketsPage> {
  // 4. Create Key for Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 5. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    // Define Data inside build to access Localization
    final List<Map<String, String>> events = [
      {"name": "Warida", "desc": l10n.islamicConference}, // Localized
      {"name": "Mirkuz", "desc": l10n.communityGathering}, // Localized
      {"name": "Keswa", "desc": l10n.culturalEvent}, // Localized
      {"name": "Kewakib", "desc": l10n.youthFestival}, // Localized
    ];

    return Scaffold(
      key: _scaffoldKey, // Assign Key
      backgroundColor: const Color(0xFF0B101D),

      // 6. Add Drawer
      endDrawer: const CustomDrawer(),

      // 7. Use CustomAppBar
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.eventTickets, // Localized "Event Tickets"
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    color: Color(0xFFCFB56C), size: 28),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      events[index]["name"]!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      events[index]["desc"]!,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
