// lib/src/core/services/notification_service.dart

// 1. IMPORT FLUTTER FOUNDATION FOR THE 'kIsWeb' CHECK
import 'package:flutter/foundation.dart';
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

    // Web doesn't support local notifications or platform-specific permissions.
    // By checking for kIsWeb here, we skip the entire setup on the web platform.
    if (kIsWeb) {
      logger.i(
          "[NotificationService] Web platform detected. Skipping initialization.");
      return;
    }

    try {
      tz.initializeTimeZones();
      final TimezoneInfo timeZoneName =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName as String));
      logger.i("Timezone initialized to: $timeZoneName");
    } catch (e) {
      logger.f("💀 FATAL: FAILED to initialize timezones.", error: e);
      return;
    }

    // --- Notification Channel Setup ---
    // This block is now safe because we've already returned if kIsWeb is true.
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // --- Initialization Settings ---
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification taps here
    });

    // --- Request Permissions ---
    // This block is also safe now.
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    }
    logger.i("[NotificationService] Initialization complete.");
  }

  /// Creates the notification channels for Android.
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

  /// Schedules new notifications for the coming day.
  static Future<void> scheduleDailyPrayerNotifications() async {
    // Also prevent background scheduling on web.
    if (kIsWeb) {
      logger.w("🚫 Skipping background scheduling on web platform.");
      return;
    }

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

  // The rest of your file remains unchanged as it is only called by
  // the public methods which are now web-guarded.

  /// Calculates prayer times and schedules them if they are in the future.
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
      final TimezoneInfo timeZoneName =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName as String));
    } catch (e) {
      logger.e("Error getting local timezone in background: $e");
    }
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    logger.w("Cancelling all scheduled notifications.");
    await _notifications.cancelAll();
  }
}
