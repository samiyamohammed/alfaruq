// lib/main.dart
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/core/theme/app_theme.dart';
import 'package:al_faruk_app/src/core/theme/theme_provider.dart';
// UPDATED: Import the new AuthGate
import 'package:al_faruk_app/src/features/auth/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/localization/afaan_oromo_localizations.dart';

final Future<void> appInitialization = _initializeApp();

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    dotenv.load(fileName: ".env"),
    settingsService.loadSettings(),
  ]);
}

void main() {
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

    return FutureBuilder(
      future: appInitialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return MaterialApp(
              home: Scaffold(
                  body: Center(
                      child: Text(
                          'Failed to initialize app: ${snapshot.error}'))));
        }
        return MaterialApp(
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
          // --- THE BIG CHANGE ---
          // The home property now points to our AuthGate, which will decide
          // whether to show the LoginScreen or the MainScreen.
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
