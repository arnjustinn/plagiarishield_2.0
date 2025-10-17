import 'package:flutter/material.dart';
import 'package:plagiarishield_sim/screens/home_screen.dart';
import 'package:plagiarishield_sim/screens/history_screen.dart';
import 'package:plagiarishield_sim/screens/account_screen.dart';

/// A reusable bottom navigation bar used across the app.
/// 
/// - Provides navigation between:
///   1. Home screen
///   2. History screen
///   3. Account screen
/// 
/// - Highlights the current active tab based on [currentIndex].
class BottomNavBar extends StatelessWidget {
  /// Index of the currently selected screen (0 = Home, 1 = History, 2 = Account).
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  /// Handles navigation when a tab item is tapped.
  /// 
  /// - If the user taps on the current tab, do nothing.
  /// - Otherwise, navigate to the selected screen and replace the current one.
  void _onNavTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Prevents unnecessary reload

    // Decide which screen to show based on the tapped index
    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const HistoryScreen();
        break;
      case 2:
        destination = const AccountScreen();
        break;
      default:
        destination = const HomeScreen();
    }

    // Replace the current screen with the new destination screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // Highlight the active tab
      onTap: (index) => _onNavTapped(context, index), // Handle tab selection
      selectedItemColor: Colors.white, // Color of the active icon/text
      unselectedItemColor: const Color.fromARGB(255, 0, 0, 0), // Inactive icons
      backgroundColor: const Color(0xFF43C5FC), // Navigation bar background
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Account',
        ),
      ],
    );
  }
}
