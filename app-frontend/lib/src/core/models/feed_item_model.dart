class FeedItem {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? audioUrl;
  final String? pdfUrl;
  final String? trailerUrl;
  final String
      type; // MOVIE, SERIES, PROPHET_HISTORY, DAWAH, DOCUMENTARY, BOOK, MUSIC_VIDEO
  final bool isLocked;
  final String? price;
  final DateTime? createdAt;
  final int? duration;
  final String? tags;

  // Book Specific Fields
  final String? authorName;
  final String? about;
  final String? genre;
  final int? pageSize;
  final int? publicationYear;

  // Hierarchy Fields
  final String? parentId; // NEW: Added this field
  final List<FeedItem> children;

  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.audioUrl,
    this.pdfUrl,
    this.trailerUrl,
    required this.type,
    this.isLocked = false,
    this.price,
    this.createdAt,
    this.duration,
    this.tags,
    this.authorName,
    this.about,
    this.genre,
    this.pageSize,
    this.publicationYear,
    this.parentId, // Add to constructor
    this.children = const [],
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // 1. Parse Price if available
    String? displayPrice;
    if (json['pricingTier'] != null && json['pricingTier'] is Map) {
      final tier = json['pricingTier'];
      if (tier['basePrice'] != null) {
        displayPrice = tier['basePrice'].toString();
      }
    }

    return FeedItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      trailerUrl: json['trailerUrl'] as String?,
      type: json['type'] as String? ?? 'UNKNOWN',
      isLocked: json['isLocked'] as bool? ?? false,
      price: displayPrice,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,

      duration: json['duration'] as int?,
      tags: json['tags'] as String?,

      // Parse Book Fields
      authorName: json['authorName'] as String?,
      about: json['about'] as String?,
      genre: json['genre'] as String?,
      pageSize: json['pageSize'] as int?,
      publicationYear: json['publicationYear'] as int?,

      // Parse Parent ID
      parentId: json['parentId'] as String?,

      // Parse Children
      children: json['children'] != null
          ? (json['children'] as List).map((c) => FeedItem.fromJson(c)).toList()
          : [],
    );
  }
}
