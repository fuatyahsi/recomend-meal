import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'community/community_hub_screen.dart';
import 'discover/discover_screen.dart';
import 'home_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/my_profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget Function()> _screenBuilders;
  late final List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _screenBuilders = [
      () => const HomeScreen(),
      () => const DiscoverScreen(),
      () => const CommunityHubScreen(),
      () => const LeaderboardScreen(),
      () => const MyProfileScreen(),
    ];
    _screens = List<Widget?>.filled(_screenBuilders.length, null);
    _screens[0] = _screenBuilders[0]();
  }

  void _ensureScreenBuilt(int index) {
    _screens[index] ??= _screenBuilders[index]();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppProvider>().locale;
    final isTr = locale.languageCode == 'tr';
    _ensureScreenBuilt(_currentIndex);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _screens.length,
          (index) => _screens[index] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _ensureScreenBuilt(index);
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: isTr ? 'Buzdolabı' : 'Fridge',
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: isTr ? 'Keşfet' : 'Discover',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: isTr ? 'Topluluk' : 'Community',
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: isTr ? 'Sıralama' : 'Ranking',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: isTr ? 'Profil' : 'Profile',
          ),
        ],
      ),
    );
  }
}
