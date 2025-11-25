// lib/src/core/services/notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
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

  static Future<void> init() async {
    logger.i("[NotificationService] Initializing...");
    try {
      tz.initializeTimeZones();

      // --- THE NEW, ROBUST FIX IS HERE ---
      // 1. Get the local timezone string, which might be messy.
      String rawTimeZone =
          (await FlutterTimezone.getLocalTimezone()).toString();

      // 2. Extract the clean IANA identifier (e.g., "Africa/Addis_Ababa")
      //    This handles the "TimezoneInfo(...)" format.
      String timeZoneName;
      if (rawTimeZone.contains('(')) {
        timeZoneName = rawTimeZone.split('(')[1].split(',')[0];
      } else {
        timeZoneName = rawTimeZone;
      }

      // 3. Use the clean name to set the location.
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      logger.i("Timezone successfully initialized to: $timeZoneName");
    } catch (e, s) {
      logger.f("💀 FATAL: FAILED to initialize timezones.",
          error: e, stackTrace: s);
      return;
    }

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {});

    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    }
    logger.i("[NotificationService] Initialization complete.");
  }

  // ... The rest of the file remains exactly the same ...
  // It is correct and does not need to be changed.

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      'prayer_time_channel',
      'Prayer Time Notifications',
      description: 'Channel for prayer time reminders.',
      importance: Importance.max,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adhanChannel);
    logger.i("Android notification channel created.");
  }

  static Future<void> scheduleDailyPrayerNotifications() async {
    logger.i("🚀 Starting background notification scheduling process...");
    try {
      await _initializeForBackground();
      await _notifications.cancelAll();
      logger.i("Cleared all previously scheduled notifications.");
      final prefs = await SharedPreferences.getInstance();
      final bool areRemindersEnabled =
          prefs.getBool('remindersEnabled') ?? true;
      if (!areRemindersEnabled) {
        logger.w("🚫 Reminders are globally disabled. Aborting scheduling.");
        return;
      }
      await _scheduleAllPrayerTimes(prefs);
      logger.i("✅ Notification scheduling process completed successfully.");
    } catch (e, s) {
      logger.e("❌ Failed to complete scheduling.", error: e, stackTrace: s);
    }
  }

  static Future<void> _scheduleAllPrayerTimes(SharedPreferences prefs) async {
    logger.i("--- Calculating and scheduling prayer notifications ---");
    Coordinates? coordinates;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
            "Location permission not granted for background scheduling.");
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 30));
      coordinates = Coordinates(position.latitude, position.longitude);
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
      logger.i("✅ Successfully fetched live location for scheduling.");
    } catch (e) {
      logger.w(
          "Could not get live location for scheduling. Falling back to cache. Reason: $e");
      final lat = prefs.getDouble('latitude');
      final lng = prefs.getDouble('longitude');
      if (lat != null && lng != null) {
        coordinates = Coordinates(lat, lng);
        logger.i("✅ Using CACHED location for scheduling: $lat, $lng");
      }
    }

    if (coordinates == null) {
      logger.e(
          "❌ ABORTING: Could not get a location. Cannot schedule notifications.");
      return;
    }

    final bool isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
    final String selectedSoundFile =
        prefs.getString('selectedSound') ?? 'adhan.mp3';
    final bool isVibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_time_channel',
        'Prayer Time Notifications',
        channelDescription: 'Channel for prayer time reminders.',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: isVibrationEnabled,
        sound: isSoundEnabled
            ? RawResourceAndroidNotificationSound(
                selectedSoundFile.split('.').first)
            : null,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(coordinates, params);

    final prayersToSchedule = {
      "Fajr": prayerTimes.fajr,
      "Dhuhr": prayerTimes.dhuhr,
      "Asr": prayerTimes.asr,
      "Maghrib": prayerTimes.maghrib,
      "Isha": prayerTimes.isha,
    };

    logger.i("Prayer times calculated for today: ${now.toIso8601String()}");

    for (var prayer in prayersToSchedule.entries) {
      final prayerName = prayer.key;
      final prayerDateTime = prayer.value;
      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(prayerDateTime, tz.local);
      if (scheduledTime.isAfter(now)) {
        logger.i("✅ Scheduling '$prayerName' at $scheduledTime");
        await _notifications.zonedSchedule(
          prayerName.hashCode,
          'Time for $prayerName Prayer',
          'The time for the $prayerName prayer has arrived.',
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        logger.w(
            "🚫 Skipping '$prayerName' because its time ($scheduledTime) has already passed today.");
      }
    }
    logger.i("--- Finished scheduling prayer notifications ---");
  }

  static Future<void> _initializeForBackground() async {
    tz.initializeTimeZones();
    try {
      String rawTimeZone =
          (await FlutterTimezone.getLocalTimezone()).toString();
      String timeZoneName;
      if (rawTimeZone.contains('(')) {
        timeZoneName = rawTimeZone.split('(')[1].split(',')[0];
      } else {
        timeZoneName = rawTimeZone;
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      logger.e("Error getting local timezone in background: $e");
    }
  }

  static Future<void> cancelAllNotifications() async {
    logger.w("Cancelling all scheduled notifications.");
    await _notifications.cancelAll();
  }
}
