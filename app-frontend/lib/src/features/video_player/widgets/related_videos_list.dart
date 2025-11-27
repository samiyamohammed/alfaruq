// lib/src/features/video_player/widgets/related_videos_list.dart
import 'package:al_faruk_app/src/core/models/video_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Needed for date formatting

class RelatedVideosList extends StatelessWidget {
  final List<Video> relatedVideos;
  final Function(Video) onVideoTap;

  const RelatedVideosList({
    super.key,
    required this.relatedVideos,
    required this.onVideoTap,
  });

  // Helper to format the date string
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final DateTime parsed = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(parsed); // Returns like "Nov 20, 2025"
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Up Next',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: relatedVideos.length,
          itemBuilder: (context, index) {
            final video = relatedVideos[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              leading: SizedBox(
                width: 120,
                height: 68, // Fixed height to prevent layout shifts
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    video.thumbnailUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              title: Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              // Combined Channel Name and Date
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "${video.channelName} • ${_formatDate(video.uploadDate)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onTap: () {
                onVideoTap(video);
              },
            );
          },
        ),
      ],
    );
  }
}
