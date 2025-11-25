import 'package:al_faruk_app/src/core/services/notification_service.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/core/theme/app_theme.dart';
import 'package:al_faruk_app/src/core/theme/theme_provider.dart';
import 'package:al_faruk_app/src/features/auth/screens/auth_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

// Localization Imports
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/localization/afaan_oromo_localizations.dart';

const dailyNotificationTask = "scheduleDailyPrayerNotifications";

@pragma('vm:entry-point')
void callbackDispatcher() {
  // --- CHANGE #1: ADDED LOGS TO SEE IF THIS EVER RUNS ---
  // This is the most important log. If you don't see this in your
  // debug console, the OS is blocking the task from starting.
  print("--- [BACKGROUND TASK]: callbackDispatcher started! ---");

  Workmanager().executeTask((task, inputData) async {
    print(
        "--- [BACKGROUND TASK]: Workmanager().executeTask called for task: $task ---");

    if (task == dailyNotificationTask) {
      // We need to re-initialize services in the background isolate
      await settingsService.loadSettings();
      await NotificationService.scheduleDailyPrayerNotifications();
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");
  await settingsService.loadSettings();
  await NotificationService.init();

  if (!kIsWeb) {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    // --- CHANGE #2: SWITCHED TO A ONE-OFF TASK FOR IMMEDIATE TESTING ---
    // Instead of waiting 12 hours, this will force the background task
    // to run about one minute after you start the app.
    Workmanager().registerOneOffTask(
      "debug-task-1", // A unique name for the one-time task
      dailyNotificationTask,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: const Duration(minutes: 1),
    );
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final theme = ref.watch(themeManagerProvider);

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'AL FARUK',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.themeMode,
      locale: settings.currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AfaanOromoLocalizationsDelegate(),
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('am'), // Amharic
        Locale('om'), // Afaan Oromo
      ],
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
