import 'package:flutter/material.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/main.dart';
import 'package:provider/provider.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuth(context);
    });
  }

  void checkAuth(BuildContext context) {
    final isAuth = context.read<AppRepository>().isAuthenticated;
    if (isAuth) {
      Navigator.pushReplacementNamed(context, NavigatorNames.base);
    } else {
      Navigator.pushReplacementNamed(context, NavigatorNames.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
