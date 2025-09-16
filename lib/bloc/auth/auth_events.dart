import 'package:equatable/equatable.dart';
import 'package:maxim_chat/bloc/auth/auth_states.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String confirmPassword;
  final String? username;

  RegisterEvent({
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.username,
  });

  @override
  List<Object> get props => [email, password];
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  ForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class ChangeAuthModeEvent extends AuthEvent {
  final AuthMode mode;

  ChangeAuthModeEvent({required this.mode});

  @override
  List<Object> get props => [mode];
}
