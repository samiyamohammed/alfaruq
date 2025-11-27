// lib/src/core/models/content_item_model.dart

class ContentItem {
  final String id;
  final String title;
  final String thumbnailUrl;
  final bool isLocked; // NEW

  const ContentItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.isLocked = false, // NEW: Default to false
  });
}
