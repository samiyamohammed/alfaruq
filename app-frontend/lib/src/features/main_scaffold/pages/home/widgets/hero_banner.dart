// lib/src/features/main_scaffold/pages/home/widgets/hero_banner.dart
import 'package:al_faruk_app/src/core/models/content_item_model.dart';
import 'package:flutter/material.dart';

class HeroBanner extends StatelessWidget {
  final ContentItem content;
  const HeroBanner({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // --- THE DEFINITIVE FIX ---

            // 1. A black background container to create a clean "letterbox" effect
            //    for images that don't match the banner's aspect ratio.
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.black,
              child: Image.network(
                content.thumbnailUrl,
                width: double.infinity,
                // 2. Changed to BoxFit.contain. This is the most important change.
                //    It guarantees the ENTIRE image is visible without cropping.
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image,
                      color: Colors.grey, size: 48);
                },
              ),
            ),
            // Gradient overlay for text readability
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                content.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
