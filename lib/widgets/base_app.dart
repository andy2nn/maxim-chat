import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:maxim_chat/screens/chat_list_screen.dart';
import 'package:maxim_chat/screens/friends_screen.dart';
import 'package:maxim_chat/screens/user_profile_screen.dart';

class BaseApp extends StatefulWidget {
  const BaseApp({super.key});

  @override
  State<BaseApp> createState() => _BaseAppState();
}

class _BaseAppState extends State<BaseApp> {
  int currentIndex = 0;

  final listWidgets = [ChatListScreen(), FriendsScreen(), UserProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
            FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
        child: listWidgets[currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),
        onTap: (value) => setState(() => currentIndex = value),
        items: [
          _buildNavItem(
            Icons.chat_bubble_outline,
            Icons.chat_bubble,
            'Chats',
            0,
          ),
          _buildNavItem(Icons.group_outlined, Icons.group, 'Friends', 1),
          _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 2),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        color: currentIndex == index
            ? Colors.blue.shade700
            : Colors.grey.shade600,
      ),
      activeIcon: Icon(activeIcon, color: Colors.blue.shade700),
      label: label,
    );
  }
}
