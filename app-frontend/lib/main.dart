// lib/main.dart
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

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/localization/afaan_oromo_localizations.dart';

const dailyNotificationTask = "scheduleDailyPrayerNotifications";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == dailyNotificationTask) {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationService.scheduleDailyPrayerNotifications();
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- THE FINAL FIX ---
  // The .env file is inside the assets folder, so we must provide the full path.
  await dotenv.load(fileName: "assets/.env");

  await settingsService.loadSettings();
  await NotificationService.init();

  if (!kIsWeb) {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    Workmanager().registerPeriodicTask(
      "daily-prayer-notification-scheduler",
      dailyNotificationTask,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
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
