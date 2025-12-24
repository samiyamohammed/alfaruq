class PricingTier {
  final String id;
  final double basePrice;
  final int baseDurationDays;
  final List<AdditionalTier> additionalTiers;

  const PricingTier({
    required this.id,
    required this.basePrice,
    required this.baseDurationDays,
    this.additionalTiers = const [],
  });

  factory PricingTier.fromJson(Map<String, dynamic> json) {
    var tiers = <AdditionalTier>[];
    if (json['additionalTiers'] != null) {
      tiers = (json['additionalTiers'] as List)
          .map((t) => AdditionalTier.fromJson(t))
          .toList();
      tiers.sort((a, b) => a.days.compareTo(b.days));
    }

    return PricingTier(
      id: json['id'] ?? '',
      basePrice: double.tryParse(json['basePrice'].toString()) ?? 0.0,
      baseDurationDays: json['baseDurationDays'] as int? ?? 7,
      additionalTiers: tiers,
    );
  }
}

class AdditionalTier {
  final int days;
  final double price;

  const AdditionalTier({required this.days, required this.price});

  factory AdditionalTier.fromJson(Map<String, dynamic> json) {
    return AdditionalTier(
      days: json['days'] as int? ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}

class FeedItem {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? youtubeUrl;
  final String? audioUrl;
  final String? pdfUrl;
  final String? trailerUrl;
  final String type;
  final bool isLocked;
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
  final String? parentId;
  final List<FeedItem> children;

  // Pricing Info
  final PricingTier? pricingTier;
  final String? price;

  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.youtubeUrl,
    this.audioUrl,
    this.pdfUrl,
    this.trailerUrl,
    required this.type,
    this.isLocked = false,
    this.createdAt,
    this.duration,
    this.tags,
    this.authorName,
    this.about,
    this.genre,
    this.pageSize,
    this.publicationYear,
    this.parentId,
    this.children = const [],
    this.pricingTier,
    this.price,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    PricingTier? tier;
    if (json['pricingTier'] != null && json['pricingTier'] is Map) {
      tier = PricingTier.fromJson(json['pricingTier']);
    }

    String? displayPrice;
    if (tier != null) {
      displayPrice = tier.basePrice.toString();
    } else if (json['price'] != null) {
      displayPrice = json['price'].toString();
    }

    return FeedItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      trailerUrl: json['trailerUrl'] as String?,
      type: json['type'] as String? ?? 'UNKNOWN',
      isLocked: json['isLocked'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      duration: json['duration'] as int?,
      tags: json['tags'] as String?,
      authorName: json['authorName'] as String?,
      about: json['about'] as String?,
      genre: json['genre'] as String?,
      pageSize: json['pageSize'] as int?,
      publicationYear: json['publicationYear'] as int?,
      parentId: json['parentId'] as String?,
      children: json['children'] != null
          ? (json['children'] as List).map((c) => FeedItem.fromJson(c)).toList()
          : [],
      pricingTier: tier,
      price: displayPrice,
    );
  }
}
