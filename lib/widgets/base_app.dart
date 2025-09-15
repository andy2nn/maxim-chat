import 'package:flutter/material.dart';
import 'package:maxim_chat/chat_list_view.dart';
import 'package:maxim_chat/friends_view.dart';
import 'package:maxim_chat/user_profile_view.dart';

class BaseApp extends StatefulWidget {
  const BaseApp({super.key});

  @override
  State<BaseApp> createState() => _BaseAppState();
}

class _BaseAppState extends State<BaseApp> {
  int currentIndex = 0;

  final listWidgets = [ChatListView(), FriendsView(), UserProfileView()];

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
