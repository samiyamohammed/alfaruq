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
        // Attempt to request if denied (optional, based on your UX flow)
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;

      return PrayerTimes.today(myCoordinates, params);
    } catch (e) {
      debugPrint("Error fetching prayer times: $e");
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
      body: OrientationBuilder(
        builder: (context, orientation) {
          final bool isLandscape = orientation == Orientation.landscape;

          return Column(
            children: [
              // 1. Prayer Times Section (Responsive)
              // If in landscape, we limit the height to ensure the compass fits
              _buildPrayerTimesSection(l10n, isLandscape),

              // 2. Main Content: Qibla Finder
              Expanded(
                child: Container(
                  // Ensure minimum space for the compass widget
                  constraints: const BoxConstraints(minHeight: 200),
                  child: const QiblahCompassView(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrayerTimesSection(AppLocalizations l10n, bool isLandscape) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, 16, 16, isLandscape ? 4 : 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mosque, color: Color(0xFFCFB56C), size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.todaysPrayerTimes,
                style: const TextStyle(
                  color: Color(0xFFCFB56C),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<PrayerTimes?>(
            future: _prayerTimesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFCFB56C),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Enable location to see prayer times",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                );
              }

              final pt = snapshot.data!;
              final fmt = DateFormat("hh:mm a");
              final next = pt.nextPrayer();

              // Helper data list for clean mapping
              final List<Map<String, dynamic>> prayers = [
                {
                  'label': l10n.prayerFajr,
                  'time': fmt.format(pt.fajr),
                  'isNext': next == Prayer.fajr
                },
                {
                  'label': l10n.prayerSunrise,
                  'time': fmt.format(pt.sunrise),
                  'isNext': next == Prayer.sunrise
                },
                {
                  'label': l10n.prayerDhuhr,
                  'time': fmt.format(pt.dhuhr),
                  'isNext': next == Prayer.dhuhr
                },
                {
                  'label': l10n.prayerAsr,
                  'time': fmt.format(pt.asr),
                  'isNext': next == Prayer.asr
                },
                {
                  'label': l10n.prayerMaghrib,
                  'time': fmt.format(pt.maghrib),
                  'isNext': next == Prayer.maghrib
                },
                {
                  'label': l10n.prayerIsha,
                  'time': fmt.format(pt.isha),
                  'isNext': next == Prayer.isha
                },
              ];

              if (isLandscape) {
                // LANDSCAPE: Use a horizontal scrollable row to save vertical height
                return SizedBox(
                  height: 65,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: prayers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final p = prayers[index];
                      return SizedBox(
                        width: 110,
                        child:
                            _buildTimeBox(p['label'], p['time'], p['isNext']),
                      );
                    },
                  ),
                );
              } else {
                // PORTRAIT: Original 2-row layout
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildTimeBox(prayers[0]['label'], prayers[0]['time'],
                            prayers[0]['isNext']),
                        const SizedBox(width: 8),
                        _buildTimeBox(prayers[1]['label'], prayers[1]['time'],
                            prayers[1]['isNext']),
                        const SizedBox(width: 8),
                        _buildTimeBox(prayers[2]['label'], prayers[2]['time'],
                            prayers[2]['isNext']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTimeBox(prayers[3]['label'], prayers[3]['time'],
                            prayers[3]['isNext']),
                        const SizedBox(width: 8),
                        _buildTimeBox(prayers[4]['label'], prayers[4]['time'],
                            prayers[4]['isNext']),
                        const SizedBox(width: 8),
                        _buildTimeBox(prayers[5]['label'], prayers[5]['time'],
                            prayers[5]['isNext']),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String label, String time, bool isNext) {
    return Expanded(
      flex: isNext
          ? 1
          : 0, // Placeholder to avoid constraint issues in flexible rows
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0B101D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isNext ? const Color(0xFFCFB56C) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isNext ? const Color(0xFFCFB56C) : Colors.white60,
                fontSize: 10,
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              maxLines: 1,
              style: TextStyle(
                color: isNext ? const Color(0xFFCFB56C) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
