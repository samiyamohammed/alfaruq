// lib/src/core/models/feed_item_model.dart

class FeedItem {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? trailerUrl;
  final String type; // 'MOVIE', 'SERIES', 'SEASON', 'EPISODE'
  final bool isLocked; // NEW
  final DateTime? createdAt;
  final List<FeedItem> children;

  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.trailerUrl,
    required this.type,
    this.isLocked = false, // NEW: Default to false
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
      isLocked: json['isLocked'] as bool? ?? false, // NEW: Parse from JSON
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      children: json['children'] != null
          ? (json['children'] as List).map((c) => FeedItem.fromJson(c)).toList()
          : [],
    );
  }
}
