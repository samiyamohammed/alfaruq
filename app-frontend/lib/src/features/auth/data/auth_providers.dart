// lib/src/features/auth/data/auth_providers.dart

import 'package:al_faruk_app/src/core/services/auth_interceptor.dart';
import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:al_faruk_app/src/core/services/youtube_service.dart';
// --- NEW IMPORTS ---
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/core/services/feed_service.dart';
// --- END NEW IMPORTS ---
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

// Provider 1: The Dio instance provider. (Unchanged)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://69.62.109.18:5001/api',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  final storageService = ref.watch(secureStorageServiceProvider);
  dio.interceptors.add(
    AuthInterceptor(storageService: storageService),
  );
  return dio;
});

// Provider 2: The AuthRepository provider. (Unchanged)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio: dio);
});

// Provider 3: The YouTubeService provider. (Unchanged)
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final dio = ref.watch(dioProvider);
  return YouTubeService(dio: dio);
});

// ---- NEW PROVIDERS ADDED FOR THE HOME PAGE FEED ----

// Provider 4: The FeedService provider (NEW)
// This provides the service instance, injecting the authenticated Dio client.
final feedServiceProvider = Provider<FeedService>((ref) {
  final dio = ref.watch(dioProvider);
  return FeedService(dio: dio);
});

// Provider 5: The FutureProvider for feed content (NEW)
// This automatically calls the fetchFeed method from the FeedService,
// handles the async state (loading/error), and caches the result for efficiency.
final feedContentProvider = FutureProvider<List<FeedItem>>((ref) {
  final feedService = ref.watch(feedServiceProvider);
  return feedService.fetchFeed();
});
