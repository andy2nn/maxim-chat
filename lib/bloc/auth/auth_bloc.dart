import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:maxim_chat/bloc/auth/events.dart';
import 'package:maxim_chat/bloc/auth/states.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  final AppRepository appRepository;

  AuthBloc({required this.appRepository})
    : super(AuthInitial(email: '', mode: AuthMode.signIn)) {
    on<LoginEvent>(_signIn);
    on<ChangeAuthModeEvent>(_onChangeAuthMode);
    on<RegisterEvent>(_register);
  }

  Future<void> _onChangeAuthMode(
    ChangeAuthModeEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthInitial(email: '', mode: event.mode));
    } catch (e) {
      AuthFailed(errorMessage: e.toString(), mode: AuthMode.signIn);
    }
  }

  Future<void> _signIn(LoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading(mode: AuthMode.signIn));
      final user = await appRepository.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      emit(AuthSuccesful(mode: AuthMode.signIn, uid: user!.uid));
    } catch (e) {
      AuthFailed(errorMessage: e.toString(), mode: AuthMode.signIn);
    }
  }

  Future<void> _register(RegisterEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading(mode: AuthMode.register));
      if (event.password.trim() != event.confirmPassword.trim()) {
        emit(
          AuthFailed(
            errorMessage: 'Пароли не совпадают',
            mode: AuthMode.forgotPassword,
          ),
        );
      } else {
        final user = await appRepository.signUp(
          event.email.trim(),
          event.password.trim(),
          usernameController.text.trim(),
        );
        emit(AuthSuccesful(mode: AuthMode.forgotPassword, uid: user!.uid));
      }
    } catch (e) {
      AuthFailed(errorMessage: e.toString(), mode: AuthMode.register);
    }
  }

  // пока без востановления
  // Future<void> _forgotPassword(
  //   ForgotPasswordEvent event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   try {
  //     emit(AuthLoading(mode: AuthMode.forgotPassword));
  //     appRepository.
  //   } catch (e) {
  //     AuthFailed(errorMessage: e.toString(), mode: AuthMode.forgotPassword);
  //   }
  // }
}
