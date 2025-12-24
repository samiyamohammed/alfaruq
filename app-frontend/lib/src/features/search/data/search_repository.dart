import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/core/models/news_item_model.dart';
import 'package:al_faruk_app/src/core/models/quran_models.dart';
import 'package:al_faruk_app/src/core/models/youtube_video_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- ARGS CLASS ---
class SearchArguments extends Equatable {
  final String query;
  final String type; // 'all', 'BOOK', 'MOVIE', 'news', 'youtube', etc.

  const SearchArguments({required this.query, required this.type});

  @override
  List<Object> get props => [query, type];
}

// --- MODEL ---
class SearchResponse {
  final List<YoutubeVideo> youtube;
  final List<FeedItem> content;
  final List<NewsItem> news;
  final List<QuranReciter> reciters;

  SearchResponse({
    this.youtube = const [],
    this.content = const [],
    this.news = const [],
    this.reciters = const [],
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      youtube: (json['youtube'] as List?)
              ?.map((e) => YoutubeVideo.fromJson(e))
              .toList() ??
          [],
      content: (json['content'] as List?)
              ?.map((e) => FeedItem.fromJson(e))
              .toList() ??
          [],
      news:
          (json['news'] as List?)?.map((e) => NewsItem.fromJson(e)).toList() ??
              [],
      reciters: (json['quran']?['reciters'] as List?)
              ?.map((e) => QuranReciter.fromJson(e))
              .toList() ??
          [],
    );
  }

  bool get isEmpty =>
      youtube.isEmpty && content.isEmpty && news.isEmpty && reciters.isEmpty;
}

// --- PROVIDER ---

final searchProvider = FutureProvider.family
    .autoDispose<SearchResponse, SearchArguments>((ref, args) async {
  if (args.query.trim().length < 2) {
    return SearchResponse();
  }

  final dio = ref.watch(dioProvider);

  try {
    // API Call with dynamic Type
    final response = await dio.get('/search', queryParameters: {
      'query': args.query,
      'type': args.type,
    });

    if (response.statusCode == 200) {
      return SearchResponse.fromJson(response.data);
    }
    return SearchResponse();
  } catch (e) {
    if (e is DioException && e.response?.statusCode == 404) {
      return SearchResponse();
    }
    rethrow;
  }
});
