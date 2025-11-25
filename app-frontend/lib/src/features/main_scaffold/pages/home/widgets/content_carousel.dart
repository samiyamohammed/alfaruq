import 'package:al_faruk_app/src/core/models/content_item_model.dart';
import 'package:flutter/material.dart';

class ContentCarousel extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  // 1. ADD THIS CALLBACK
  final Function(ContentItem item)? onItemTap;

  const ContentCarousel({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap, // 2. ADD TO CONSTRUCTOR
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
          height: 160, // Adjust height as needed
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              // 3. WRAP THE CARD IN INKWELL/GESTURE DETECTOR
              return GestureDetector(
                onTap: () {
                  if (onItemTap != null) {
                    onItemTap!(item);
                  }
                },
                child: Container(
                  width: 110, // Adjust width as needed
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(item.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                    color: Colors.grey[900],
                  ),
                  child: Align(
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
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(8)),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
