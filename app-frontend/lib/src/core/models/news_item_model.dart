class NewsItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String author;
  final String? thumbnailUrl;
  final DateTime? createdAt;

  const NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    this.thumbnailUrl,
    this.createdAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      author: json['author'] as String? ?? 'Al-Faruk',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
