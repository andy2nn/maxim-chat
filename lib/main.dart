import 'package:flutter/material.dart';
import 'package:maxim_chat/widgets/base_app.dart';

void main() {
  runApp(const MaximChatApp());
}

class MaximChatApp extends StatelessWidget {
  const MaximChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {'/': (context) => BaseApp()},
      initialRoute: '/',
    );
  }
}
