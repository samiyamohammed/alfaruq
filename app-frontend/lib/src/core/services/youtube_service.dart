import 'package:al_faruk_app/src/core/models/video_model.dart';
import 'package:dio/dio.dart';

class YouTubeService {
  final Dio _dio;
  YouTubeService({required Dio dio}) : _dio = dio;

  // Updated method signature to optionally accept status, defaulting to 'public'
  Future<List<Video>> fetchPlaylistVideos({
    required String playlistId,
    String status = 'public',
  }) async {
    const endpoint = '/youtube/playlist';

    try {
      // 1. PASS THE STATUS IN queryParameters
      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'status': status,
          // If the API eventually needs the playlistId, you would add it here too:
          // 'playlistId': playlistId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data;

        return items.map((item) {
          return Video(
            id: item['videoId'] ?? '',
            title: item['title'] ?? 'No Title',
            thumbnailUrl: item['thumbnailUrl'] ?? '',
            description: item['description'] ?? '',
            // Parsing the status from the response if you need to check it locally
            // status: item['status'] ?? '',
            channelName: 'Alfaruk Multimedia',
            uploadDate:
                item['publishedAt'] ?? '', // Mapped publishedAt from screenshot
            viewCount: '',
          );
        }).toList();
      } else {
        throw Exception(
            'Failed to load playlist. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      }
      throw Exception(
          'Failed to connect to the server. Please check your network.');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
