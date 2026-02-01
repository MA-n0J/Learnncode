import 'package:flutter/material.dart';
import 'package:learnncode/screens/community/community.dart';
import 'package:learnncode/screens/leaderboard/leaderboard.dart';
import 'package:learnncode/screens/level/level_main.dart';
import 'package:learnncode/screens/profile/profile.dart';

class NavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onIndexChanged;

  const NavigationBarWidget({
    super.key,
    required this.currentIndex,
    this.onIndexChanged,
  });

  void _onItemTapped(BuildContext context, int index) {
    print('Navigating to index: $index'); // Debug print
    if (onIndexChanged != null) {
      onIndexChanged!(index);
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LevelDesignScreen()),
          );
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LeaderboardPage()),
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CommunityParent()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      selectedItemColor: const Color(0xFF58CC02),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Leaderboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum),
          label: 'Community',
        ),
      ],
    );
  }
}
