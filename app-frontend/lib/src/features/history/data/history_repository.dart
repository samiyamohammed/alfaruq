import 'dart:convert';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/history/data/history_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

// A provider to listen to history changes (for the UI list)
final watchHistoryProvider = FutureProvider<List<HistoryItem>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getHistory();
});

class HistoryRepository {
  static const String _key = 'watch_history';

  Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString(_key);
    if (rawData == null) return [];

    final List<dynamic> list = jsonDecode(rawData);
    return list.map((e) => HistoryItem.fromJson(e)).toList();
  }

  Future<int> getSavedPosition(String contentId) async {
    final history = await getHistory();
    final item = history.firstWhere(
      (e) => e.contentId == contentId,
      orElse: () => HistoryItem(
        contentId: '',
        title: '',
        type: '',
        lastPositionSeconds: 0,
        totalDurationSeconds: 0,
        lastWatched: DateTime.now(),
      ),
    );
    return item.lastPositionSeconds;
  }

  Future<void> saveProgress({
    required FeedItem item,
    required int positionSeconds,
    required int durationSeconds,
    String? parentTitle, // Pass Series title if available
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<HistoryItem> history = await getHistory();

    // 1. Remove existing entry for this content (to move it to top)
    history.removeWhere((e) => e.contentId == item.id);

    // 2. Create new entry
    final newItem = HistoryItem(
      contentId: item.id,
      title: item.title,
      thumbnailUrl: item.thumbnailUrl,
      type: item.type,
      lastPositionSeconds: positionSeconds,
      totalDurationSeconds: durationSeconds,
      lastWatched: DateTime.now(),
      parentId: item.parentId,
      parentTitle: parentTitle,
    );

    // 3. Add to top
    history.insert(0, newItem);

    // 4. Limit history size (e.g., keep last 50 items)
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    // 5. Save
    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
