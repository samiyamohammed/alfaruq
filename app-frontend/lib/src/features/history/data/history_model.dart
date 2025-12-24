import 'dart:convert';

class HistoryItem {
  final String contentId;
  final String title;
  final String? thumbnailUrl;
  final String type; // MOVIE, EPISODE, etc.
  final int lastPositionSeconds;
  final int totalDurationSeconds;
  final DateTime lastWatched;

  // Extra fields for Series context
  final String? parentId; // Series ID if it's an episode
  final String? parentTitle; // Series Title

  HistoryItem({
    required this.contentId,
    required this.title,
    this.thumbnailUrl,
    required this.type,
    required this.lastPositionSeconds,
    required this.totalDurationSeconds,
    required this.lastWatched,
    this.parentId,
    this.parentTitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'type': type,
      'lastPositionSeconds': lastPositionSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'lastWatched': lastWatched.toIso8601String(),
      'parentId': parentId,
      'parentTitle': parentTitle,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      contentId: json['contentId'],
      title: json['title'],
      thumbnailUrl: json['thumbnailUrl'],
      type: json['type'] ?? 'UNKNOWN',
      lastPositionSeconds: json['lastPositionSeconds'] ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] ?? 0,
      lastWatched: DateTime.parse(json['lastWatched']),
      parentId: json['parentId'],
      parentTitle: json['parentTitle'],
    );
  }

  double get progress {
    if (totalDurationSeconds == 0) return 0.0;
    return lastPositionSeconds / totalDurationSeconds;
  }
}
