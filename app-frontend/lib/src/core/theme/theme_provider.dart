// lib/src/core/theme/theme_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

// This is a global instance of your ThemeManager.
final themeManager = ThemeManager();

// This is the Riverpod provider that makes the themeManager instance
// available to the app. Widgets will listen to this provider to get the
// service and rebuild whenever the theme mode changes.
final themeManagerProvider = ChangeNotifierProvider<ThemeManager>((ref) {
  return themeManager;
});
