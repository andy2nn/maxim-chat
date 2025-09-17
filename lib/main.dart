import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maxim_chat/bloc/chat/chat_bloc.dart';
import 'package:maxim_chat/bloc/profile/profile_bloc.dart';
import 'package:maxim_chat/bloc/friends/friends_bloc.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/data/repositories/chat_repository.dart';
import 'package:maxim_chat/screens/auth_screen.dart';
import 'package:maxim_chat/screens/check_auth_screen.dart';
import 'package:maxim_chat/widgets/base_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final chatRepository = ChatRepository();
  runApp(MaximChatApp(chatRepository: chatRepository));
}

class MaximChatApp extends StatelessWidget {
  final ChatRepository chatRepository;
  const MaximChatApp({super.key, required this.chatRepository});

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
        final appRepository = AppRepository.createSync(prefs);

        return MultiProvider(
          providers: [
            Provider<AppRepository>.value(value: appRepository),
            Provider<ChatRepository>.value(value: chatRepository),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ChatBloc>(
                create: (context) => ChatBloc(chatRepository: chatRepository),
              ),
              BlocProvider<FriendsBloc>(
                create: (context) => FriendsBloc(
                  appRepository: appRepository,
                  currentUserId: appRepository.userId!,
                ),
              ),
              BlocProvider<ProfileBloc>(
                create: (context) => ProfileBloc(appRepository: appRepository),
              ),
            ],
            child: MaterialApp(
              routes: {
                NavigatorNames.base: (context) => BaseApp(),
                NavigatorNames.checkAuth: (context) => CheckAuthScreen(),
                NavigatorNames.auth: (context) => AuthScreen(),
              },
              initialRoute: NavigatorNames.checkAuth,
            ),
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
