import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/src/features/splash/screens/video_splash_screen.dart';
import 'package:al_faruk_app/src/core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/localization/afaan_oromo_localizations.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/core/services/notification_service.dart';

void main() {
  // 1. Core Binding - Essential for all plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 2. RUN APP IMMEDIATELY
  // We do not load any services here.
  // Everything is moved into the VideoSplashScreen to prevent the black screen hang.
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
      home: const VideoSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
