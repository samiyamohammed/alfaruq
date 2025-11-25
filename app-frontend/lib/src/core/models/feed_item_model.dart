// lib/src/core/models/feed_item_model.dart

class FeedItem {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? trailerUrl;
  final String type; // 'MOVIE', 'SERIES', 'SEASON', 'EPISODE'
  final DateTime? createdAt; // Made nullable to be safe with nested items
  final List<FeedItem> children; // NEW: Recursive list for Seasons/Episodes

  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.trailerUrl,
    required this.type,
    this.createdAt,
    this.children = const [],
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      trailerUrl: json['trailerUrl'] as String?,
      type: json['type'] as String? ?? 'UNKNOWN',
      // Parse date safely
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      // RECURSIVE MAPPING for Series -> Seasons -> Episodes
      children: json['children'] != null
          ? (json['children'] as List).map((c) => FeedItem.fromJson(c)).toList()
          : [],
    );
  }
}
