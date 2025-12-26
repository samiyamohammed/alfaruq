import 'package:adhan/adhan.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/qiblah_compass_view.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class KhadimPage extends ConsumerStatefulWidget {
  const KhadimPage({super.key});

  @override
  ConsumerState<KhadimPage> createState() => _KhadimPageState();
}

class _KhadimPageState extends ConsumerState<KhadimPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<PrayerTimes?> _prayerTimesFuture;

  @override
  void initState() {
    super.initState();
    _prayerTimesFuture = _getPrayerTimes();
  }

  Future<PrayerTimes?> _getPrayerTimes() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;

      return PrayerTimes.today(myCoordinates, params);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.khadim,
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () {
          ref.read(bottomNavIndexProvider.notifier).state = 0;
        },
      ),
      body: Column(
        children: [
          // 1. Prayer Times Card (Essential Info at the top)
          _buildPrayerTimesCard(l10n),

          // 2. Main Content: Qibla Finder (Now the primary feature)
          const Expanded(
            child: QiblahCompassView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesCard(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mosque, color: Color(0xFFCFB56C), size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.todaysPrayerTimes,
                style: const TextStyle(
                    color: Color(0xFFCFB56C), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<PrayerTimes?>(
            future: _prayerTimesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Color(0xFFCFB56C)),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Enable location to see prayer times",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                );
              }

              final pt = snapshot.data!;
              final fmt = DateFormat("hh:mm a");
              final next = pt.nextPrayer();

              return Column(
                children: [
                  Row(
                    children: [
                      _buildTimeBox(l10n.prayerFajr, fmt.format(pt.fajr),
                          next == Prayer.fajr),
                      const SizedBox(width: 8),
                      _buildTimeBox(l10n.prayerSunrise, fmt.format(pt.sunrise),
                          next == Prayer.sunrise),
                      const SizedBox(width: 8),
                      _buildTimeBox(l10n.prayerDhuhr, fmt.format(pt.dhuhr),
                          next == Prayer.dhuhr),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTimeBox(l10n.prayerAsr, fmt.format(pt.asr),
                          next == Prayer.asr),
                      const SizedBox(width: 8),
                      _buildTimeBox(l10n.prayerMaghrib, fmt.format(pt.maghrib),
                          next == Prayer.maghrib),
                      const SizedBox(width: 8),
                      _buildTimeBox(l10n.prayerIsha, fmt.format(pt.isha),
                          next == Prayer.isha),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String label, String time, bool isNext) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B101D),
          borderRadius: BorderRadius.circular(6),
          border: isNext
              ? Border.all(color: const Color(0xFFCFB56C), width: 1)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isNext ? const Color(0xFFCFB56C) : Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isNext ? const Color(0xFFCFB56C) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
