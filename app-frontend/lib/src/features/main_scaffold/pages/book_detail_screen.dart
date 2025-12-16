import 'package:al_faruk_app/generated/app_localizations.dart'; // 1. Import Localization
import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/iqra_library_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/pdf_viewer_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart'; // 2. Import CustomAppBar
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart'; // 3. Import CustomDrawer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final FeedItem book;
  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  // 4. Create Key for Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 5. Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    // Check if audio/pdf is available
    final bool hasAudio =
        widget.book.audioUrl != null && widget.book.audioUrl!.isNotEmpty;
    final bool hasPdf =
        widget.book.pdfUrl != null && widget.book.pdfUrl!.isNotEmpty;

    return Scaffold(
      key: _scaffoldKey, // Assign Key
      backgroundColor: const Color(0xFF0B101D),

      // 6. Add Drawer
      endDrawer: const CustomDrawer(),

      // 7. Use CustomAppBar
      appBar: CustomAppBar(
        isSubPage: true,
        title: l10n.bookDetails, // Localized Title
        scaffoldKey: _scaffoldKey,
        onLeadingPressed: () => Navigator.pop(context),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 220,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withOpacity(0.1), blurRadius: 10)
                ],
                image: DecorationImage(
                  image: NetworkImage(widget.book.thumbnailUrl ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline,
                    color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.book.authorName ?? l10n.unknownAuthor, // Localized
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // --- READ BOOK BUTTON ---
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasPdf
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  pdfUrl: widget.book.pdfUrl!,
                                  title: widget.book.title,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.menu_book, color: Colors.black),
                    label: Text(l10n.readBook), // Localized
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCFB56C),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // --- LISTEN BOOK BUTTON ---
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasAudio
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IqraLibraryScreen(
                                  initialTabIndex: 1, // 1 = Audio Tab
                                  targetedBookId: widget.book.id,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: Icon(Icons.headset,
                        color: hasAudio ? Colors.white : Colors.white24),
                    label: Text(l10n.listenBook, // Localized
                        style: TextStyle(
                            color: hasAudio ? Colors.white : Colors.white24)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: hasAudio
                              ? const Color(0xFFCFB56C)
                              : Colors.white12),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Info Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151E32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem(Icons.category_outlined, l10n.genre,
                          widget.book.genre ?? "-"), // Localized
                      const SizedBox(width: 16),
                      _buildInfoItem(Icons.description_outlined, l10n.pages,
                          "${widget.book.pageSize ?? '-'}"), // Localized
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem(Icons.calendar_today_outlined, l10n.year,
                          "${widget.book.publicationYear ?? '-'}"), // Localized
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.bookSummary, // Localized
                  style: const TextStyle(
                      color: Color(0xFFCFB56C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(
              widget.book.description,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (widget.book.about != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.aboutThisBook, // Localized
                    style: const TextStyle(
                        color: Color(0xFFCFB56C),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text(
                widget.book.about!,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFCFB56C), size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
