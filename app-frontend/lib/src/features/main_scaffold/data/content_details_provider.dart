// lib/src/features/main_scaffold/data/content_details_provider.dart

import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contentDetailsProvider =
    FutureProvider.family<FeedItem, String>((ref, id) async {
  final dio = ref.watch(dioProvider);

  try {
    // This endpoint returns the recursive tree (Series -> Season -> Episode)
    final response = await dio.get('/feed/$id');

    if (response.statusCode == 200) {
      return FeedItem.fromJson(response.data);
    } else {
      throw Exception('Failed to load content details');
    }
  } catch (e) {
    throw Exception('Error fetching details: $e');
  }
});
