import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/screens/auth_screen.dart';
import 'package:maxim_chat/screens/check_auth_screen.dart';
import 'package:maxim_chat/widgets/base_app.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaximChatApp());
}

class MaximChatApp extends StatelessWidget {
  const MaximChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => AppRepository.create(),
      child: MaterialApp(
        routes: {
          NavigatorNames.base: (context) => BaseApp(),
          NavigatorNames.checkAuth: (context) => CheckAuthScreen(),
          NavigatorNames.auth: (context) => AuthScreen(),
        },
        initialRoute: 'checkAuth',
      ),
    );
  }
}

class NavigatorNames {
  static const String base = '/';
  static const String checkAuth = 'checkAuth';
  static const String auth = 'auth';
}
