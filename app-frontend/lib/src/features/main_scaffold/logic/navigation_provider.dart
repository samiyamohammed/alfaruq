import 'package:flutter_riverpod/flutter_riverpod.dart';

// Controls the Bottom Navigation Bar Index (0: Home, 1: Videos, 2: Library, etc.)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Controls the Tab Index inside Videos Page (0: Playlists, 1: Music Videos)
final videosTabIndexProvider = StateProvider<int>((ref) => 0);

// Controls the Tab Index inside Content Library Page (0: Movies, 1: Series, 2: Trailers)
final libraryTabIndexProvider = StateProvider<int>((ref) => 0);
