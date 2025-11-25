import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/content_library_page.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home_page.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/qiblah_page.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/videos_page.dart';
import 'package:al_faruk_app/src/features/profile/screens/profile_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  static final List<Widget> _pages = <Widget>[
    const HomePage(), // Index 0
    const VideosPage(), // Index 1
    const ContentLibraryPage(), // Index 2
    const QiblahPage(), // Index 3
    const ProfileScreen(), // Index 4
  ];

  void _onItemTapped(int index) {
    // Update the provider state
    ref.read(bottomNavIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider state to update UI
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      // Hide CustomAppBar on Profile screen (Index 4)
      appBar: selectedIndex == 4 ? null : const CustomAppBar(),
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
