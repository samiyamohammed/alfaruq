// lib/src/core/models/video_model.dart

class Video {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelName;
  final String viewCount;
  final String uploadDate;
  final String description;

  const Video({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelName,
    required this.viewCount,
    required this.uploadDate,
    required this.description,
  });

  // --- NEW: Factory to parse the API JSON ---
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['videoId'] ?? '',
      title: json['title'] ?? 'No Title',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      // JSON doesn't have channelName, defaulting to your channel
      channelName: 'Alfaruk Multimedia',
      // JSON doesn't have viewCount, leaving empty or setting a default
      viewCount: '',
      // Maps 'publishedAt' to 'uploadDate'
      uploadDate: json['publishedAt'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
