import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const _storageKey = 'recent_searches_key';

  // Load history from local storage on startup
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_storageKey) ?? [];
    state = history;
  }

  // Add a term with business rules: Limit 10, Move duplicates to top
  Future<void> addSearchTerm(String term) async {
    final trimmedTerm = term.trim();
    if (trimmedTerm.isEmpty) return;

    final List<String> newList = List.from(state);

    // Remove if already exists (to move it to top)
    newList.removeWhere((e) => e.toLowerCase() == trimmedTerm.toLowerCase());

    // Insert at the beginning
    newList.insert(0, trimmedTerm);

    // EXPERT UPDATE: Enforce Limit 10
    if (newList.length > 10) {
      state = newList.sublist(0, 10);
    } else {
      state = newList;
    }

    // Persist to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  // Remove a specific search term
  Future<void> removeSearchTerm(String term) async {
    final newList = List<String>.from(state);
    newList.remove(term);
    state = newList;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  // Clear all history
  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});
