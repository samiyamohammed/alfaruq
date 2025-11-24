// lib/src/core/models/feed_item_model.dart

// A detailed model to represent an item from the /api/feed endpoint.
class FeedItem {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? videoUrl; // Can be null
  final String? trailerUrl; // Can be null
  final String type; // 'MOVIE' or 'SERIES'
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.videoUrl,
    this.trailerUrl,
    required this.type,
    required this.createdAt,
  });

  // A factory constructor to create an instance from a JSON map.
  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      videoUrl: json['videoUrl'] as String?,
      trailerUrl: json['trailerUrl'] as String?,
      type: json['type'] as String,
      // Safely parse the date string into a DateTime object.
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
