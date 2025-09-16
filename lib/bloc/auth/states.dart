import 'package:equatable/equatable.dart';

enum AuthMode { signIn, register, forgotPassword }

abstract class AuthState extends Equatable {
  final AuthMode mode;
  const AuthState({required this.mode});

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {
  final String? email;

  const AuthInitial({required this.email, required super.mode});

  @override
  List<Object> get props => [mode, email ?? ''];
}

class AuthLoading extends AuthState {
  const AuthLoading({required super.mode});

  @override
  List<Object> get props => [mode];
}

class AuthSuccesful extends AuthState {
  final String uid;
  const AuthSuccesful({required super.mode, required this.uid});

  @override
  List<Object> get props => [mode, uid];
}

class AuthFailed extends AuthState {
  final String errorMessage;
  const AuthFailed({required this.errorMessage, required super.mode});
}
