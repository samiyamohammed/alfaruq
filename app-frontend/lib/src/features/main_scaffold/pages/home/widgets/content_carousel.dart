// lib/src/features/main_scaffold/pages/home/widgets/content_carousel.dart
import 'package:al_faruk_app/src/core/models/content_item_model.dart';
import 'package:flutter/material.dart';

class ContentCarousel extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  final Function(ContentItem item)? onItemTap;

  const ContentCarousel({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return GestureDetector(
                onTap: () {
                  if (onItemTap != null) {
                    onItemTap!(item);
                  }
                },
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(item.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                    color: Colors.grey[900],
                  ),
                  // Changed child to Stack to allow positioning the Lock icon
                  child: Stack(
                    children: [
                      // Text Overlay
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black87, Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(8)),
                          ),
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // NEW: Lock Icon
                      if (item.isLocked)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
