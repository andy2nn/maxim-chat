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
      body: listWidgets[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.abc_rounded),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.abc_rounded),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.abc_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: currentIndex,
        onTap: (value) => setState(() {
          currentIndex = value;
        }),
      ),
    );
  }
}
