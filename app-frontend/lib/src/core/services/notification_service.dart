import 'dart:io';
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

  // Unified Init Method
  static Future<void> init({bool isBackground = false}) async {
    if (!isBackground) logger.i("[NotificationService] Initializing...");

    // 1. Timezone Setup
    try {
      tz.initializeTimeZones();
      String rawTimeZone =
          (await FlutterTimezone.getLocalTimezone()).toString();
      // Handle "Asia/Calcutta(IST)" format
      if (rawTimeZone.contains('(')) {
        rawTimeZone = rawTimeZone.split('(')[1].split(',')[0];
      }
      tz.setLocalLocation(tz.getLocation(rawTimeZone));
    } catch (e) {
      if (!isBackground) logger.e("Timezone init failed", error: e);
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Plugin Setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);

    // 3. Create Channel (Important for Android 8+)
    await _createNotificationChannels();
  }

  static Future<void> scheduleDailyPrayerNotifications() async {
    try {
      // Access Prefs directly (No Riverpod)
      final prefs = await SharedPreferences.getInstance();

      // Check global switch
      if (prefs.getBool('remindersEnabled') == false) {
        return;
      }

      await _scheduleAllPrayerTimes(prefs);
    } catch (e, s) {
      print("❌ Error scheduling notifications: $e");
      print(s);
    }
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      'prayer_time_channel',
      'Prayer Time Notifications',
      description: 'Channel for prayer time reminders.',
      importance: Importance.max,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adhanChannel);
  }

  static Future<void> _scheduleAllPrayerTimes(SharedPreferences prefs) async {
    Coordinates? coordinates;

    // 1. Try Cached Location (Preferred for Background)
    final double? cachedLat = prefs.getDouble('latitude');
    final double? cachedLng = prefs.getDouble('longitude');

    if (cachedLat != null && cachedLng != null) {
      coordinates = Coordinates(cachedLat, cachedLng);
    } else {
      // 2. Try Live Location (Only works if app is in foreground or specific permissions)
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 5));
          coordinates = Coordinates(position.latitude, position.longitude);
        }
      } catch (_) {
        // Ignore errors in background
      }
    }

    if (coordinates == null) {
      print("⚠️ No location found. Skipping schedule.");
      return;
    }

    // Prepare Details
    final bool isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
    final String soundName =
        (prefs.getString('selectedSound') ?? 'adhan').split('.').first;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_time_channel',
        'Prayer Time Notifications',
        channelDescription: 'Channel for prayer time reminders.',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true, // Wakes up screen
        sound: isSoundEnabled
            ? RawResourceAndroidNotificationSound(soundName)
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

    // Schedule
    await _notifications.cancelAll(); // Clear old to avoid duplicates

    for (var entry in prayersMap.entries) {
      final String prayerName = entry.key;
      final DateTime rawTime = entry.value;

      tz.TZDateTime scheduledTime = tz.TZDateTime.from(rawTime, tz.local);

      // CRITICAL FIX: If time passed today, schedule for tomorrow
      // This ensures the daily repeat logic kicks in correctly.
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      print("📅 Scheduled $prayerName for $scheduledTime");

      await _notifications.zonedSchedule(
        prayerName.hashCode,
        'Time for $prayerName',
        'The time for $prayerName prayer has arrived.',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats Daily
      );
    }
  }
}
