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

  // Helper to ensure timezone is never null
  static Future<void> _ensureTimezoneInitialized() async {
    try {
      // Accessing tz.local throws the error if not set.
      // We check it inside a try block.
      tz.local;
    } catch (_) {
      tz.initializeTimeZones();
      try {
        // FIX: Capture as dynamic or TimezoneInfo to handle the object return
        final timezoneResult = await FlutterTimezone.getLocalTimezone();

        // Access the 'name' property if it's a TimezoneInfo object,
        // or use it directly if it's already a String.
        String rawTimeZone;
        if (timezoneResult is String) {
          rawTimeZone = timezoneResult as String;
        } else {
          // Newer versions return a TimezoneInfo object which has a .name field
          rawTimeZone = timezoneResult.toString();
          // If the above still fails, use: rawTimeZone = (timezoneResult as dynamic).name;
        }

        if (rawTimeZone.contains('(')) {
          rawTimeZone = rawTimeZone.split('(')[1].split(',')[0];
        }

        tz.setLocalLocation(tz.getLocation(rawTimeZone));
      } catch (e) {
        // Fallback to UTC if native lookup fails
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

    await _createNotificationChannels();
  }

  static Future<void> scheduleDailyPrayerNotifications() async {
    try {
      // Ensure timezones are ready before doing anything else
      await _ensureTimezoneInitialized();

      final prefs = await SharedPreferences.getInstance();

      final bool isEnabled = prefs.getBool('remindersEnabled') ?? true;
      if (!isEnabled) {
        await _notifications.cancelAll();
        print("🔕 Reminders disabled. Cancelled all notifications.");
        return;
      }

      await _scheduleAllPrayerTimes(prefs);
    } catch (e) {
      print("❌ Error scheduling notifications: $e");
    }
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      'prayer_time_channel',
      'Prayer Time Notifications',
      description: 'Channel for prayer time reminders.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adhanChannel);
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
      print("⚠️ No coordinates available. Cannot schedule prayer times.");
      return;
    }

    // Read Settings
    final bool isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
    final bool isVibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;

    final String selectedSoundRaw =
        prefs.getString('selectedSound') ?? 'adhan.mp3';
    final String soundResourceName = selectedSoundRaw.split('.').first;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_time_channel',
        'Prayer Time Notifications',
        channelDescription: 'Channel for prayer time reminders.',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        enableVibration: isVibrationEnabled,
        sound: isSoundEnabled
            ? RawResourceAndroidNotificationSound(soundResourceName)
            : null,
      ),
    );

    // Calculate Prayers
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

    await _notifications.cancelAll();

    for (var entry in prayersMap.entries) {
      final String prayerName = entry.key;
      tz.TZDateTime scheduledTime = tz.TZDateTime.from(entry.value, tz.local);

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      print(
          "📅 Scheduling $prayerName at $scheduledTime with sound: $soundResourceName");

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
