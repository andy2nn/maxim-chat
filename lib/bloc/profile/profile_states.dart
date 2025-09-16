import 'package:equatable/equatable.dart';
import 'package:maxim_chat/data/models/user.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();

  @override
  List<Object> get props => [];
}

class ProfileLoading extends ProfileState {
  @override
  List<Object> get props => [];
}

class ProfileLoaded extends ProfileState {
  final bool isCurrentUser;
  final User user;
  const ProfileLoaded({required this.user, required this.isCurrentUser});

  @override
  List<Object> get props => [isCurrentUser, user];
}

class ProfileError extends ProfileState {
  final String errorMessage;
  const ProfileError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}

class ProfileUpdated extends ProfileState {
  final User user;
  const ProfileUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

class ProfileEditMode extends ProfileState {
  final User user;

  const ProfileEditMode(this.user);

  @override
  List<Object> get props => [user];
}
