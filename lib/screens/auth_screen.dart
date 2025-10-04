import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_events.dart';
import '../bloc/auth/auth_states.dart';
import '../data/repositories/app_repository.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AppRepository appRepository;

  @override
  void initState() {
    super.initState();
    appRepository = context.read<AppRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(appRepository: appRepository),
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWeb = constraints.maxWidth > 800;
            final formWidth = isWeb ? 500.0 : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 24 : 16,
                  vertical: 40,
                ),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: formWidth),
                      child: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthSuccesful) {
                            Navigator.popAndPushNamed(
                              context,
                              NavigatorNames.base,
                            );
                          }
                        },
                        builder: (context, state) {
                          final bloc = context.read<AuthBloc>();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble,
                                size: isWeb ? 80 : 60,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _getTitle(state.mode),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              if (state is AuthFailed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    state.errorMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (state.mode == AuthMode.signIn)
                                _buildSignInForm(context, bloc, isWeb),
                              if (state.mode == AuthMode.register)
                                _buildRegisterForm(context, bloc, isWeb),
                              if (state.mode == AuthMode.forgotPassword)
                                _buildForgotForm(context, bloc, isWeb),
                              const SizedBox(height: 24),
                              _buildModeSelector(context, state),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getTitle(AuthMode mode) {
    switch (mode) {
      case AuthMode.signIn:
        return "Welcome Back 👋";
      case AuthMode.register:
        return "Create Account ✨";
      case AuthMode.forgotPassword:
        return "Reset Password 🔑";
    }
  }

  Widget _buildModeSelector(BuildContext context, AuthState state) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        _buildModeButton(context, 'Login', AuthMode.signIn, state.mode),
        _buildModeButton(context, 'Register', AuthMode.register, state.mode),
        _buildModeButton(
          context,
          'Forgot',
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
    final selected = mode == currentMode;
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      selectedColor: Colors.blue.shade100,
      onSelected: (_) =>
          context.read<AuthBloc>().add(ChangeAuthModeEvent(mode: mode)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon) : null,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context, AuthBloc bloc, bool isWeb) {
    return Column(
      children: [
        _buildTextField(
          controller: bloc.emailController,
          hint: "Email",
          icon: Icons.email,
        ),
        _buildTextField(
          controller: bloc.passwordController,
          hint: "Password",
          obscure: true,
          icon: Icons.lock,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: isWeb ? 56 : 48,
          child: ElevatedButton(
            onPressed: () => bloc.add(
              LoginEvent(
                email: bloc.emailController.text,
                password: bloc.passwordController.text,
              ),
            ),
            child: const Text("Login"),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context, AuthBloc bloc, bool isWeb) {
    return Column(
      children: [
        _buildTextField(
          controller: bloc.usernameController,
          hint: "Username",
          icon: Icons.person,
        ),
        _buildTextField(
          controller: bloc.emailController,
          hint: "Email",
          icon: Icons.email,
        ),
        _buildTextField(
          controller: bloc.passwordController,
          hint: "Password",
          obscure: true,
          icon: Icons.lock,
        ),
        _buildTextField(
          controller: bloc.confirmPasswordController,
          hint: "Confirm Password",
          obscure: true,
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: isWeb ? 56 : 48,
          child: ElevatedButton(
            onPressed: () => bloc.add(
              RegisterEvent(
                email: bloc.emailController.text,
                password: bloc.passwordController.text,
                confirmPassword: bloc.confirmPasswordController.text,
                username: bloc.usernameController.text,
              ),
            ),
            child: const Text("Register"),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotForm(BuildContext context, AuthBloc bloc, bool isWeb) {
    return Column(
      children: [
        _buildTextField(
          controller: bloc.emailController,
          hint: "Enter your email",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: isWeb ? 56 : 48,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement reset password
            },
            child: const Text("Send Reset Link"),
          ),
        ),
      ],
    );
  }
}
