import 'package:al_faruk_app/generated/app_localizations.dart';
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home/widgets/horizontal_content_section.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/iqra_library_screen.dart';
import 'package:flutter/material.dart';

class IqraSection extends StatelessWidget {
  final List<FeedItem> books;
  const IqraSection({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(l10n.iqraReadListen,
                  style: const TextStyle(
                      color: Color(0xFFCFB56C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  // --- SWAPPED BUTTONS ---
                  // 1. PDF Books (Left, Gold, Index 0)
                  Expanded(
                    child: _iqraButton(context, Icons.menu_book, "PDF Books",
                        const Color(0xFFCFB56C), 0),
                  ),
                  const SizedBox(width: 12),
                  // 2. Audio Books (Right, Blue, Index 1)
                  Expanded(
                    child: _iqraButton(context, Icons.headset, "Audio Books",
                        const Color(0xFF151E32), 1),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Horizontal List of Books
        if (books.isNotEmpty)
          HorizontalContentSection(
            title: "",
            items: books.take(10).toList(),
            isPortrait: true,
          ),
      ],
    );
  }

  Widget _iqraButton(BuildContext context, IconData icon, String label,
      Color color, int tabIndex) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IqraLibraryScreen(initialTabIndex: tabIndex),
          ),
        );
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: color == const Color(0xFFCFB56C)
                    ? Colors.black
                    : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color == const Color(0xFFCFB56C)
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
