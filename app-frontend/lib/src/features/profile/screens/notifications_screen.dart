//notifications screen
import 'package:al_faruk_app/src/features/prayer_times/models/prayer_time_model.dart';
import 'package:al_faruk_app/src/features/prayer_times/screens/notification_settings_screen.dart';
import 'package:al_faruk_app/src/features/prayer_times/widgets/prayer_time_card.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:al_faruk_app/generated/app_localizations.dart'; // Import

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<PrayerTimes> _prayerTimesFuture;

  @override
  void initState() {
    super.initState();
    _prayerTimesFuture = _getPrayerTimes();
  }

  Future<PrayerTimes> _getPrayerTimes() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final myCoordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(myCoordinates, params);

    return prayerTimes;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.prayerReminders), // Localized
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ));
            },
          ),
        ],
      ),
      body: FutureBuilder<PrayerTimes>(
        future: _prayerTimesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.error}: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final prayerTimes = snapshot.data!;
            final formattedTime = DateFormat.jm();

            // Map English technical names to Localized Strings
            final prayerDataList = [
              PrayerTime(
                  name: l10n.prayerFajr,
                  time: formattedTime.format(prayerTimes.fajr),
                  icon: Icons.brightness_4_outlined),
              PrayerTime(
                  name: l10n.prayerSunrise,
                  time: formattedTime.format(prayerTimes.sunrise),
                  icon: Icons.wb_sunny_outlined),
              PrayerTime(
                  name: l10n.prayerDhuhr,
                  time: formattedTime.format(prayerTimes.dhuhr),
                  icon: Icons.wb_sunny),
              PrayerTime(
                  name: l10n.prayerAsr,
                  time: formattedTime.format(prayerTimes.asr),
                  icon: Icons.brightness_6_outlined),
              PrayerTime(
                  name: l10n.prayerMaghrib,
                  time: formattedTime.format(prayerTimes.maghrib),
                  icon: Icons.brightness_5_outlined),
              PrayerTime(
                  name: l10n.prayerIsha,
                  time: formattedTime.format(prayerTimes.isha),
                  icon: Icons.nights_stay_outlined),
            ];

            final nextPrayer = prayerTimes.nextPrayer();
            // Note: Determining next prayer highlighting relies on adhan's internal English names (Fajr, Dhuhr etc).
            // We should compare indices or use the original adhan Name to find which is next,
            // then highlight the corresponding index in our localized list.
            // Simplified logic: Check index or just leave highlight logic based on original English comparison if possible.
            // Since `prayerDataList` names are now localized (e.g., "Subhi"), they won't match "Fajr".
            // FIX: We can highlight based on index or time, but for now let's assume standard order.

            // To fix highlighting, we need to know WHICH one is next from the library.
            // Adhan library returns `Prayer.fajr`, etc.
            // Let's map Prayer enum to our list index.
            int nextIndex = -1;
            switch (nextPrayer) {
              case Prayer.fajr:
                nextIndex = 0;
                break;
              case Prayer.sunrise:
                nextIndex = 1;
                break;
              case Prayer.dhuhr:
                nextIndex = 2;
                break;
              case Prayer.asr:
                nextIndex = 3;
                break;
              case Prayer.maghrib:
                nextIndex = 4;
                break;
              case Prayer.isha:
                nextIndex = 5;
                break;
              default:
                nextIndex = -1;
            }

            return ListView.builder(
              itemCount: prayerDataList.length,
              itemBuilder: (context, index) {
                final prayer = prayerDataList[index];
                final bool isNext = index == nextIndex;
                return PrayerTimeCard(
                  prayerTime: prayer,
                  isNextPrayer: isNext,
                );
              },
            );
          }
          return Center(child: Text(l10n.noData));
        },
      ),
    );
  }
}
