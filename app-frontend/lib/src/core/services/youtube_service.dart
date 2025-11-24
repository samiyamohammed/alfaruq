// lib/src/core/services/youtube_service.dart
import 'dart:convert';
import 'package:al_faruk_app/src/core/models/video_model.dart';
// 1. IMPORT DIO AND REMOVE HTTP
import 'package:dio/dio.dart';

class YouTubeService {
  // 2. ACCEPT DIO IN THE CONSTRUCTOR
  final Dio _dio;
  YouTubeService({required Dio dio}) : _dio = dio;

  // 3. REMOVE HARDCODED TOKEN AND BASE URL
  // The token is now handled automatically by the AuthInterceptor.

  Future<List<Video>> fetchPlaylistVideos({required String playlistId}) async {
    // The endpoint is relative to the baseUrl configured in your dioProvider.
    const endpoint = '/youtube/playlist';

    try {
      // 4. USE DIO FOR THE GET REQUEST
      // The AuthInterceptor will automatically add the correct auth headers.
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        // Dio automatically decodes JSON, so response.data is already a List.
        final List<dynamic> items = response.data;

        return items.map((item) {
          return Video(
            id: item['videoId'] ?? '',
            title: item['title'] ?? 'No Title',
            thumbnailUrl: item['thumbnailUrl'] ?? '',
            description: item['description'] ?? '',
            // Provide default values for fields not in the API response.
            channelName: 'Alfaruk Multimedia',
            uploadDate: '',
            viewCount: '',
          );
        }).toList();
      } else {
        throw Exception(
            'Failed to load playlist. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // 5. HANDLE DIO-SPECIFIC ERRORS
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      }
      // Provide a more general error for other network issues.
      throw Exception(
          'Failed to connect to the server. Please check your network.');
    } catch (e) {
      // Catch any other unexpected errors during parsing.
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
