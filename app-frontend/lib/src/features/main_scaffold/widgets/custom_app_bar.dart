import 'package:al_faruk_app/src/features/notifications/logic/notification_provider.dart';
import 'package:al_faruk_app/src/features/notifications/screens/notification_center_screen.dart';
import 'package:al_faruk_app/src/features/search/screens/search_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool isSubPage;
  final String? title;
  final VoidCallback? onLeadingPressed;
  // This callback is now optional, used if a specific page wants to handle search itself
  // otherwise, we default to the global search screen.
  final ValueChanged<String>? onSearchChanged;

  const CustomAppBar({
    super.key,
    this.scaffoldKey,
    this.isSubPage = false,
    this.title,
    this.onLeadingPressed,
    this.onSearchChanged,
  });

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        // If local search handler exists, notify it
        widget.onSearchChanged?.call("");
      }
    });
  }

  void _performGlobalSearch(String query) {
    if (query.trim().isEmpty) return;

    // Close the search bar visual state
    _toggleSearch();

    // Navigate to Results Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: widget.isSubPage ? 0 : 16.0,

      // --- LEADING ---
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _toggleSearch,
            )
          : (widget.isSubPage
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                  onPressed: () {
                    if (widget.onLeadingPressed != null) {
                      widget.onLeadingPressed!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                )
              : null),

      // --- TITLE ---
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search, // Show 'Search' button
              onSubmitted: (value) {
                if (widget.onSearchChanged != null) {
                  // Local page override
                  widget.onSearchChanged!(value);
                } else {
                  // Global Search
                  _performGlobalSearch(value);
                }
              },
              onChanged: (value) {
                // Keep local listeners updated if they exist
                if (widget.onSearchChanged != null) {
                  widget.onSearchChanged!(value);
                }
              },
              decoration: const InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            )
          : (widget.isSubPage && widget.title != null
              ? Text(
                  widget.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCFB56C),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Row(
                  children: [
                    if (!widget.isSubPage) ...[
                      Image.asset(
                        'assets/images/logo_symbol.png',
                        height: 32,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.mosque, color: Color(0xFFCFB56C)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'AL-FARUK',
                      style: TextStyle(
                        color: Color(0xFFCFB56C),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black45),
                        ],
                      ),
                    ),
                  ],
                )),

      // --- ACTIONS ---
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search, size: 26, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
            onPressed: _toggleSearch,
          ),
        if (!_isSearching) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.notifications_none_outlined,
                  size: 26, color: Colors.white),
            ),
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const NotificationCenterScreen(),
              ));
            },
          ),
          const SizedBox(width: 8),
          if (widget.scaffoldKey != null)
            IconButton(
              icon: const Icon(Icons.menu, size: 26, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white10),
              onPressed: () {
                widget.scaffoldKey!.currentState?.openEndDrawer();
              },
            ),
          const SizedBox(width: 8),
        ]
      ],
    );
  }
}
