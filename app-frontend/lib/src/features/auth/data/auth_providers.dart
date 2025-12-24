// lib/src/features/auth/data/auth_providers.dart

import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/core/models/news_item_model.dart';
import 'package:al_faruk_app/src/core/models/quran_models.dart';
import 'package:al_faruk_app/src/core/models/youtube_video_model.dart';
import 'package:al_faruk_app/src/core/services/auth_interceptor.dart';
import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:al_faruk_app/src/core/services/youtube_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://69.62.109.18:5001/api',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );
  final storageService = ref.watch(secureStorageServiceProvider);
  dio.interceptors.add(
    AuthInterceptor(storageService: storageService),
  );
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio: dio);
});
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final dio = ref.watch(dioProvider);
  return YouTubeService(dio: dio);
});

// --- BOOKMARKS LOGIC ---

class BookmarksNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final Dio dio;
  BookmarksNotifier(this.dio) : super(const AsyncValue.loading()) {
    fetchBookmarks();
  }

  Future<void> fetchBookmarks() async {
    try {
      final response = await dio.get('/bookmarks');
      if (response.statusCode == 200) {
        final List items = response.data['items'] ?? [];
        final set = items.map((e) => e['itemId'].toString()).toSet();
        state = AsyncValue.data(set);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleBookmark(FeedItem item) async {
    await _performToggle(item.id, item.type);
  }

  Future<void> toggleReciterBookmark(QuranReciter reciter) async {
    await _performToggle(reciter.id, 'reciter');
  }

  // FIX: Added for individual Surah/Recitations
  Future<void> toggleTafsirBookmark(QuranRecitation recitation) async {
    await _performToggle(recitation.id, 'tafsir');
  }

  Future<void> _performToggle(String itemId, String type) async {
    final currentSet = state.value ?? {};
    final isBookmarked = currentSet.contains(itemId);

    try {
      if (isBookmarked) {
        await dio.delete('/bookmarks', data: {
          'type': type,
          'itemId': itemId,
        });
        state = AsyncValue.data({...currentSet}..remove(itemId));
      } else {
        await dio.post('/bookmarks', data: {
          'type': type,
          'itemId': itemId,
        });
        state = AsyncValue.data({...currentSet}..add(itemId));
      }
    } catch (e) {
      print("Bookmark Toggle Error: $e");
    }
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<Set<String>>>((ref) {
  return BookmarksNotifier(ref.watch(dioProvider));
});

final youtubeContentProvider = FutureProvider<List<YoutubeVideo>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio
        .get('/youtube/playlist', queryParameters: {'status': 'public'});
    return (response.data as List)
        .map((e) => YoutubeVideo.fromJson(e))
        .take(50)
        .toList();
  } catch (e) {
    throw _handleError(e);
  }
});

// --- NEW PROVIDER: Filter Videos by Channel ---
final channelVideosProvider =
    FutureProvider.family<List<YoutubeVideo>, String>((ref, channelName) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/youtube/playlist', queryParameters: {
      'status': 'public',
      'channel': channelName, // Pass the exact string from your dropdown
    });

    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((e) => YoutubeVideo.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    throw _handleError(e);
  }
});

String _handleError(Object e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return "Connection timed out. Please check your internet.";
    } else if (e.type == DioExceptionType.connectionError) {
      return "No internet connection.";
    } else if (e.type == DioExceptionType.badResponse) {
      return "Server error (${e.response?.statusCode}). Please try again later.";
    }
  }
  return "Something went wrong. Please try again.";
}

// --- CONTENT PROVIDERS ---

final feedContentProvider = FutureProvider<List<FeedItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/feed', queryParameters: {
      'page': 1,
      'limit': 50,
    });

    if (response.statusCode == 200) {
      final data = response.data;
      final List items = data['data'];
      return items.map((e) => FeedItem.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    throw _handleError(e);
  }
});

final feedDetailsProvider =
    FutureProvider.family<FeedItem, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/feed/$id');
    if (response.statusCode == 200) {
      return FeedItem.fromJson(response.data);
    }
    throw "Failed to load details.";
  } catch (e) {
    throw _handleError(e);
  }
});

// --- PROVIDERS ---

final quranLanguagesProvider = FutureProvider<List<QuranLanguage>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/quran/languages');
    return (response.data as List)
        .map((e) => QuranLanguage.fromJson(e))
        .toList();
  } catch (e) {
    throw _handleError(e);
  }
});

final quranRecitersProvider =
    FutureProvider.family<List<QuranReciter>, String?>((ref, languageId) async {
  final dio = ref.watch(dioProvider);
  try {
    final Map<String, dynamic> queryParams = {};
    if (languageId != null && languageId != 'all')
      queryParams['languageId'] = languageId;
    final response =
        await dio.get('/quran/reciters', queryParameters: queryParams);
    return (response.data as List)
        .map((e) => QuranReciter.fromJson(e))
        .toList();
  } catch (e) {
    throw _handleError(e);
  }
});

final quranStructureProvider = FutureProvider<List<QuranJuz>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/quran/structure');
    return (response.data as List).map((e) => QuranJuz.fromJson(e)).toList();
  } catch (e) {
    throw _handleError(e);
  }
});

// --- FIX: Using String key to prevent infinite re-fetching loop ---
final reciterRecitationsProvider =
    FutureProvider.family<List<QuranContentItem>, String>(
        (ref, uniqueKey) async {
  final dio = ref.watch(dioProvider);

  // Parse the key "reciterId|languageId"
  final parts = uniqueKey.split('|');
  final reciterId = parts[0];
  final languageId = parts.length > 1 ? parts[1] : '';

  try {
    print(
        "🚀 API CALL: /quran/reciters/$reciterId/recitations?languageId=$languageId");

    final response = await dio.get(
      '/quran/reciters/$reciterId/recitations',
      queryParameters: {'languageId': languageId},
    );

    print("✅ API SUCCESS: Status ${response.statusCode}");

    if (response.statusCode == 200) {
      final List data = response.data;
      // Parse the JSON into our nested Model
      return data.map((e) => QuranContentItem.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    print("❌ API ERROR: $e");
    throw _handleError(e);
  }
});

final newsProvider = FutureProvider<List<NewsItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/news', queryParameters: {
      'page': 1,
      'limit': 5,
    });
    if (response.statusCode == 200) {
      final data = response.data;
      final List items = data['data'];
      return items.map((e) => NewsItem.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    throw _handleError(e);
  }
});
