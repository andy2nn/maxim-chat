import 'package:flutter/material.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/main.dart';
import 'package:provider/provider.dart';

class CheckAuthScreen extends StatelessWidget {
  const CheckAuthScreen({super.key});

  void checkAuth(BuildContext context) {
    final isAuth = context.read<AppRepository>().isAuthenticated;
    if (isAuth) {
      Navigator.popAndPushNamed(context, NavigatorNames.base);
    } else {
      Navigator.popAndPushNamed(context, NavigatorNames.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
