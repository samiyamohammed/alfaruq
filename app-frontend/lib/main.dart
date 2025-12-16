import 'dart:ui';
import 'package:al_faruk_app/src/core/services/notification_service.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/core/theme/app_theme.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/auth/screens/auth_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:al_faruk_app/src/core/services/fcm_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/localization/afaan_oromo_localizations.dart';

const dailyNotificationTask = "scheduleDailyPrayerNotifications";
const uniqueTaskName = "daily-prayer-notification-scheduler";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("🤠 [BG-TASK] Starting Background Isolate");

    try {
      if (task == dailyNotificationTask) {
        debugPrint("🤠 [BG-TASK] Running Schedule Logic...");
        await NotificationService.init(isBackground: true);
        await NotificationService.scheduleDailyPrayerNotifications();
      }
      debugPrint("🤠 [BG-TASK] Finished Successfully");
      return Future.value(true);
    } catch (err, stack) {
      debugPrint("💀 [BG-TASK] ERROR: $err");
      debugPrint(stack.toString());
      return Future.value(false);
    }
  });
}

Future<void> _requestAllPermissions() async {
  await [
    Permission.location,
    Permission.notification,
    Permission.scheduleExactAlarm,
  ].request();
}

Future<void> _updateAndCacheLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', position.latitude);
    await prefs.setDouble('longitude', position.longitude);
    debugPrint(
        "✅ Location cached: ${position.latitude}, ${position.longitude}");
  } catch (e) {
    debugPrint("Error caching location: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await dotenv.load(fileName: "assets/.env");

  // 1. Load General Settings
  await settingsService.loadSettings();

  // 2. Request Permissions
  await _requestAllPermissions();

  // 3. Init Services
  await NotificationService.init(isBackground: false);
  await _updateAndCacheLocation();

  // 4. Background Tasks (Mobile Only)
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      await Workmanager().cancelByUniqueName(uniqueTaskName);
      await Workmanager().registerPeriodicTask(
        uniqueTaskName,
        dailyNotificationTask,
        frequency: kDebugMode
            ? const Duration(minutes: 15)
            : const Duration(hours: 12),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      debugPrint("✅ WorkManager Configured");
    } catch (e) {
      debugPrint("⚠️ WorkManager Error: $e");
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFCM();
    });
  }

  Future<void> _initFCM() async {
    try {
      final dio = ref.read(dioProvider);
      final fcmService = FCMService(dio: dio);
      await fcmService.initialize(ref);
    } catch (e) {
      debugPrint("⛔️ FCM Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'AL FARUK',

      // --- THEME CONFIGURATION ---
      // Strictly use the custom AppTheme we defined (Deep Blue & Gold)
      theme: AppTheme.theme,
      darkTheme: AppTheme.theme, // Force dark theme even if system is light
      themeMode: ThemeMode.dark, // Always dark

      // --- LOCALIZATION ---
      locale: settings.currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AfaanOromoLocalizationsDelegate(),
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
        Locale('om'),
      ],
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
