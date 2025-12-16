import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple provider that just holds the theme mode (Always Dark for this design)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);