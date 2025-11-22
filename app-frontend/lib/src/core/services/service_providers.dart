// lib/src/core/services/service_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_service.dart';

// This is a global instance of your service, which is fine since it's a singleton.
final settingsService = SettingsService();

// This is the Riverpod provider that makes the settingsService available to the app.
// Widgets will listen to this provider to get the service and rebuild when it changes.
final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  return settingsService;
});
