// lib/src/core/services/feed_service.dart

import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:dio/dio.dart';

class FeedService {
  final Dio _dio;
  FeedService({required Dio dio}) : _dio = dio;

  Future<List<FeedItem>> fetchFeed() async {
    const endpoint = '/feed';

    try {
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data;
        // Use the fromJson factory to parse each item in the list.
        return items.map((item) => FeedItem.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load feed. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to connect to the server: ${e.message}');
    } catch (e) {
      throw Exception(
          'An unexpected error occurred while parsing the feed: $e');
    }
  }
}
