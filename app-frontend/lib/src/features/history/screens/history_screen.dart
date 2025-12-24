import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/player/screens/content_player_screen.dart';
import 'package:al_faruk_app/src/features/history/data/history_model.dart';
import 'package:al_faruk_app/src/features/history/data/history_repository.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF0B101D),
      endDrawer: const CustomDrawer(),
      appBar: CustomAppBar(
        isSubPage: true,
        title: "Watch History",
        scaffoldKey: scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: historyAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFCFB56C))),
        error: (err, stack) => Center(
            child: Text("Error: $err",
                style: const TextStyle(color: Colors.white))),
        data: (historyList) {
          if (historyList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("No watch history yet",
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Clear History Button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFF151E32),
                          title: const Text("Clear History?",
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              "This will remove all your watch progress.",
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text("Cancel")),
                            TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text("Clear",
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref
                            .read(historyRepositoryProvider)
                            .clearHistory();
                        ref.invalidate(watchHistoryProvider);
                      }
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white54, size: 18),
                    label: const Text("Clear All",
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
              ),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyList.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = historyList[index];
                    return _buildHistoryItem(context, item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryItem item) {
    double progress = 0.0;
    bool isFinished = false;
    String timeLeftString = "";

    if (item.totalDurationSeconds > 0) {
      progress = item.lastPositionSeconds / item.totalDurationSeconds;
      if (progress > 1.0) progress = 1.0;

      final remaining = item.totalDurationSeconds - item.lastPositionSeconds;

      if ((progress > 0.95) ||
          (remaining < 10 && item.totalDurationSeconds > 30)) {
        isFinished = true;
        timeLeftString = "Finished";
        progress = 1.0;
      } else {
        if (remaining >= 3600) {
          final hours = (remaining / 3600).floor();
          final mins = ((remaining % 3600) / 60).ceil();
          timeLeftString = "${hours}h ${mins}m left";
        } else {
          final mins = (remaining / 60).ceil();
          timeLeftString = "${mins}m left";
        }
      }
    } else {
      timeLeftString = "Unknown duration";
    }

    String subtitle = "";
    if (item.parentTitle != null) {
      subtitle += "${item.parentTitle} • ";
    }
    subtitle += timeLeftString;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContentPlayerScreen(
              contentId: item.contentId,
            ),
          ),
        );
      },
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF151E32),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.network(
                    item.thumbnailUrl ?? '',
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                        width: 120, height: 90, color: Colors.grey[900]),
                  ),
                  if (item.totalDurationSeconds > 0)
                    SizedBox(
                      width: 120,
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.black45,
                        color:
                            isFinished ? Colors.green : const Color(0xFFCFB56C),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: isFinished ? Colors.greenAccent : Colors.white54,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(isFinished ? Icons.replay : Icons.play_circle_outline,
                color: const Color(0xFFCFB56C), size: 28),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
