import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxim_chat/bloc/auth/auth_bloc.dart';
import 'package:maxim_chat/bloc/auth/auth_events.dart';
import 'package:maxim_chat/bloc/auth/auth_states.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AppRepository appRepository;
  @override
  void initState() {
    appRepository = context.read<AppRepository>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(appRepository: appRepository),
      child: Scaffold(
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccesful) {
              Navigator.popAndPushNamed(context, NavigatorNames.base);
            }
          },
          builder: (context, state) {
            final bloc = context.read<AuthBloc>();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state is AuthFailed) Text(state.errorMessage),

                  if (state.mode == AuthMode.signIn)
                    _buildSignInForm(context, bloc),
                  if (state.mode == AuthMode.register)
                    _buildRegisterForm(context, bloc),
                  if (state.mode == AuthMode.forgotPassword)
                    _buildForgotForm(context, bloc),
                  _buildModeSelector(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, AuthState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeButton(context, 'Login', AuthMode.signIn, state.mode),
        _buildModeButton(context, 'Register', AuthMode.register, state.mode),
        _buildModeButton(
          context,
          'Forgot Password',
          AuthMode.forgotPassword,
          state.mode,
        ),
      ],
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String text,
    AuthMode mode,
    AuthMode currentMode,
  ) {
    return TextButton(
      onPressed: () {
        context.read<AuthBloc>().add(ChangeAuthModeEvent(mode: mode));
      },
      style: TextButton.styleFrom(
        foregroundColor: mode == currentMode ? Colors.blue : Colors.grey,
      ),
      child: Text(text),
    );
  }

  Widget _buildSignInForm(BuildContext context, AuthBloc bloc) {
    return Column(
      children: [
        TextField(controller: bloc.emailController),
        TextField(controller: bloc.passwordController),
        ElevatedButton(
          onPressed: () => bloc.add(
            LoginEvent(
              email: bloc.emailController.text,
              password: bloc.passwordController.text,
            ),
          ),
          child: Text('auth'),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context, AuthBloc bloc) {
    return Column(
      children: [
        TextField(controller: bloc.emailController),
        TextField(controller: bloc.passwordController),
        TextField(controller: bloc.confirmPasswordController),
        TextField(controller: bloc.usernameController),
        ElevatedButton(
          onPressed: () => bloc.add(
            RegisterEvent(
              email: bloc.emailController.text,
              password: bloc.passwordController.text,
              confirmPassword: bloc.confirmPasswordController.text,
              username: bloc.usernameController.text,
            ),
          ),
          child: Text('register'),
        ),
      ],
    );
  }

  // Пока без востановления
  Widget _buildForgotForm(BuildContext context, AuthBloc bloc) {
    return Column(
      children: [
        TextField(controller: bloc.emailController),
        ElevatedButton(onPressed: () {}, child: Text('send link')),
      ],
    );
  }
}
