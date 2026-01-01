import 'package:al_faruk_app/src/features/search/data/search_history_provider.dart';
import 'package:al_faruk_app/src/features/search/screens/search_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchEntryScreen extends ConsumerStatefulWidget {
  const SearchEntryScreen({super.key});

  @override
  ConsumerState<SearchEntryScreen> createState() => _SearchEntryScreenState();
}

class _SearchEntryScreenState extends ConsumerState<SearchEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _currentQuery = "";

  @override
  void initState() {
    super.initState();
    // Automatically open keyboard when screen appears
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _executeSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Save to the 10-item history
    ref.read(searchHistoryProvider.notifier).addSearchTerm(trimmed);

    // Navigate to results page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SearchResultsScreen(query: trimmed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(searchHistoryProvider);

    // LIVE FILTERING / SIMILARITY LOGIC
    // Filters the 10-item history to show only what matches current typing
    final filteredHistory = _currentQuery.isEmpty
        ? history
        : history
            .where((term) =>
                term.toLowerCase().contains(_currentQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E32),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: (val) => setState(() => _currentQuery = val),
          onSubmitted: _executeSearch,
          decoration: const InputDecoration(
            hintText: "Search AL-FARUK...",
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_currentQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54),
              onPressed: () {
                _controller.clear();
                setState(() => _currentQuery = "");
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (filteredHistory.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredHistory.length,
                itemBuilder: (context, index) {
                  final term = filteredHistory[index];
                  return ListTile(
                    onTap: () => _executeSearch(term),
                    leading: const Icon(Icons.history,
                        color: Colors.white38, size: 22),
                    title: Text(
                      term,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    // Fill icon (north_west): Fills the search bar without executing yet
                    trailing: IconButton(
                      icon: const Icon(Icons.north_west,
                          color: Colors.white24, size: 18),
                      onPressed: () {
                        _controller.text = term;
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                        setState(() => _currentQuery = term);
                      },
                    ),
                    // Standard mobile UX: Long press to delete a specific item from the 10
                    onLongPress: () {
                      _showDeleteDialog(term);
                    },
                  );
                },
              ),
            ),

          // Clear History Button (Optional but recommended for full-screen UX)
          if (history.isNotEmpty && _currentQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clearHistory(),
                child: const Text("CLEAR SEARCH HISTORY",
                    style: TextStyle(
                        color: Color(0xFFCFB56C),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String term) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151E32),
        title: const Text("Remove from history?",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
            "Do you want to remove '$term' from your recent searches?",
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                ref.read(searchHistoryProvider.notifier).removeSearchTerm(term);
                Navigator.pop(context);
              },
              child: const Text("REMOVE",
                  style: TextStyle(color: Color(0xFFCFB56C)))),
        ],
      ),
    );
  }
}
