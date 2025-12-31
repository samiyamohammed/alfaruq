import 'dart:ui';
import 'package:al_faruk_app/src/core/services/notification_service.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/core/theme/app_theme.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/auth/screens/auth_gate.dart';
import 'package:al_faruk_app/src/features/player/widgets/floating_player_overlay.dart'; // NEW IMPORT
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
import 'package:just_audio_background/just_audio_background.dart';

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
  try {
    await [
      Permission.location,
      Permission.notification,
      Permission.scheduleExactAlarm,
    ].request();
  } catch (e) {
    debugPrint("Permission request error: $e");
  }
}

Future<void> _updateAndCacheLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', position.latitude);
    await prefs.setDouble('longitude', position.longitude);
  } catch (e) {
    debugPrint("Error caching location: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await dotenv.load(fileName: "assets/.env");

    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.alfaruk.app.audio',
      androidNotificationChannelName: 'Al-Faruk Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );

    await settingsService.loadSettings();

    if (!kIsWeb) {
      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
      } catch (e) {
        debugPrint("⚠️ WorkManager Init Error: $e");
      }
    }
  } catch (e) {
    debugPrint("Critical initialization error: $e");
  }

  runApp(const ProviderScope(child: MyApp()));

  _postStartupInit();
}

Future<void> _postStartupInit() async {
  await _requestAllPermissions();
  await NotificationService.init(isBackground: false);
  await _updateAndCacheLocation();

  if (!kIsWeb) {
    try {
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
    } catch (e) {
      debugPrint("⚠️ WorkManager Error: $e");
    }
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFCM();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Logic for notification click...
    }
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
      theme: AppTheme.theme,
      darkTheme: AppTheme.theme,
      themeMode: ThemeMode.dark,
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
      debugShowCheckedModeBanner: false,
      // WRAPPING THE APP CONTENT WITH THE FLOATING OVERLAY
      builder: (context, child) {
        return FloatingPlayerOverlay(child: child!);
      },
      home: const AuthGate(),
    );
  }
}
