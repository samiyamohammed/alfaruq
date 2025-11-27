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
            // 1. Background Image
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.black,
              child: Image.network(
                content.thumbnailUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image,
                      color: Colors.grey, size: 48);
                },
              ),
            ),
            // 2. Gradient overlay
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
            // 3. Title
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
            // 4. NEW: Lock Icon (Top Right)
            if (content.isLocked)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54, // Semi-transparent background
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
