import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';

class NotificationService {
  static final logger = Logger();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> _ensureTimezoneInitialized() async {
    try {
      tz.local;
    } catch (_) {
      tz.initializeTimeZones();
      try {
        final timezoneResult = await FlutterTimezone.getLocalTimezone();
        String rawTimeZone = timezoneResult.toString();

        if (rawTimeZone.contains('(')) {
          rawTimeZone = rawTimeZone.split('(')[1].split(',')[0];
        }
        tz.setLocalLocation(tz.getLocation(rawTimeZone));
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  static Future<void> init({bool isBackground = false}) async {
    if (!isBackground) logger.i("[NotificationService] Initializing...");

    await _ensureTimezoneInitialized();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  /// EXPERT FIX: Dynamically creates a channel based on the sound name.
  /// This bypasses Android's "Locked Sound" issue.
  static Future<void> _createNotificationChannel(
      String soundResourceName) async {
    final String channelId = 'prayer_channel_$soundResourceName';

    final AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      channelId,
      'Prayer Reminders',
      description: 'Notifications for prayer times.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound(soundResourceName),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adhanChannel);
  }

  static Future<void> scheduleDailyPrayerNotifications() async {
    try {
      await _ensureTimezoneInitialized();
      final prefs = await SharedPreferences.getInstance();

      final bool isEnabled = prefs.getBool('remindersEnabled') ?? true;

      // Always clear old ones before rescheduling
      await _notifications.cancelAll();

      if (!isEnabled) {
        print("🔕 Reminders disabled. All notifications cleared.");
        return;
      }

      await _scheduleAllPrayerTimes(prefs);
    } catch (e) {
      print("❌ Error scheduling notifications: $e");
    }
  }

  static Future<void> _scheduleAllPrayerTimes(SharedPreferences prefs) async {
    Coordinates? coordinates;

    final double? cachedLat = prefs.getDouble('latitude');
    final double? cachedLng = prefs.getDouble('longitude');

    if (cachedLat != null && cachedLng != null) {
      coordinates = Coordinates(cachedLat, cachedLng);
    } else {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 5));
          coordinates = Coordinates(position.latitude, position.longitude);
        }
      } catch (_) {}
    }

    if (coordinates == null) {
      print("⚠️ No coordinates found. Using fallback coordinates.");
      coordinates = Coordinates(9.03, 38.74); // Default to Addis Ababa
    }

    // Read latest settings
    final bool isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
    final bool isVibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    final String selectedSoundRaw =
        prefs.getString('selectedSound') ?? 'adhan.mp3';

    // Convert 'adhan.mp3' -> 'adhan'
    final String soundResourceName = selectedSoundRaw.split('.').first;

    // Register the channel for this specific sound
    await _createNotificationChannel(soundResourceName);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_channel_$soundResourceName', // Must match the channel created above
        'Prayer Reminders',
        channelDescription: 'Notifications for prayer times.',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: isVibrationEnabled,
        playSound: isSoundEnabled,
        sound: isSoundEnabled
            ? RawResourceAndroidNotificationSound(soundResourceName)
            : null,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes.today(coordinates, params);

    final prayersMap = {
      "Fajr": prayerTimes.fajr,
      "Dhuhr": prayerTimes.dhuhr,
      "Asr": prayerTimes.asr,
      "Maghrib": prayerTimes.maghrib,
      "Isha": prayerTimes.isha,
    };

    for (var entry in prayersMap.entries) {
      final String prayerName = entry.key;
      tz.TZDateTime scheduledTime = tz.TZDateTime.from(entry.value, tz.local);

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      print(
          "📅 Scheduled $prayerName at $scheduledTime with sound resource: $soundResourceName");

      await _notifications.zonedSchedule(
        prayerName.hashCode,
        'Time for $prayerName',
        'The time for $prayerName prayer has arrived.',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
