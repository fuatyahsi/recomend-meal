import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'community/community_hub_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/my_profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CommunityHubScreen(),
    LeaderboardScreen(),
    MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppProvider>().locale;
    final isTr = locale.languageCode == 'tr';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: isTr ? 'Buzdolabı' : 'Fridge',
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
