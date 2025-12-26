import 'package:al_faruk_app/src/features/main_scaffold/logic/navigation_provider.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/home_page.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/iqra_library_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/khadim_page.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/service_page.dart';
import 'package:al_faruk_app/src/features/main_scaffold/pages/yene_movies_page.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_app_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_bottom_nav_bar.dart';
import 'package:al_faruk_app/src/features/main_scaffold/widgets/custom_drawer.dart';
import 'package:al_faruk_app/src/features/profile/screens/app_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // 1. Create the Key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<Widget> _pages = <Widget>[
    const HomePage(), // Index 0
    const YeneMoviesPage(), // Index 1
    const ServicePage(), // Index 2
    const KhadimPage(), // Index 3
    const IqraLibraryScreen(), // Index 4
    const AppSettingsScreen(), // Index 5
  ];

  void _onItemTapped(int index) {
    ref.read(bottomNavIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      // 2. Assign the Key here
      key: _scaffoldKey,

      extendBodyBehindAppBar: true,

      // 3. Pass the Key to the AppBar
      appBar:
          selectedIndex == 0 ? CustomAppBar(scaffoldKey: _scaffoldKey) : null,

      endDrawer: const CustomDrawer(),

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
