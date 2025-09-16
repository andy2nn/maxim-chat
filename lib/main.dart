import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/screens/auth_screen.dart';
import 'package:maxim_chat/screens/check_auth_screen.dart';
import 'package:maxim_chat/widgets/base_app.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaximChatApp());
}

class MaximChatApp extends StatelessWidget {
  const MaximChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(body: Center(child: Text('Error loading app'))),
          );
        }

        final prefs = snapshot.data!;
        return Provider<AppRepository>(
          create: (context) => AppRepository.createSync(prefs),
          child: MaterialApp(
            routes: {
              NavigatorNames.base: (context) => BaseApp(),
              NavigatorNames.checkAuth: (context) => CheckAuthScreen(),
              NavigatorNames.auth: (context) => AuthScreen(),
            },
            initialRoute: NavigatorNames.checkAuth,
          ),
        );
      },
    );
  }
}

class NavigatorNames {
  static const String base = '/';
  static const String checkAuth = 'checkAuth';
  static const String auth = 'auth';
}
