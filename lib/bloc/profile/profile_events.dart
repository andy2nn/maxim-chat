import 'package:equatable/equatable.dart';
import 'package:maxim_chat/data/models/user.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final String uid;
  final bool isCurrentUser;

  LoadProfileEvent({required this.uid, required this.isCurrentUser});

  @override
  List<Object> get props => [uid, isCurrentUser];
}

class EditProfileEvent extends ProfileEvent {
  final User user;
  EditProfileEvent({required this.user});

  @override
  List<Object> get props => [user];
}

class UpdateProfileEvent extends ProfileEvent {
  final String userId;
  final String? username;
  final String? email;
  final String? photoBase64;
  final String? bio;

  UpdateProfileEvent({
    required this.userId,
    this.username,
    this.email,
    this.photoBase64,
    this.bio,
  });

  @override
  List<Object> get props => [
    userId,
    username ?? '',
    email ?? '',
    photoBase64 ?? '',
    bio ?? '',
  ];
}

class CancelEditEvent extends ProfileEvent {}

class SendMessageEvent extends ProfileEvent {
  final String uid;
  SendMessageEvent({required this.uid});

  @override
  List<Object> get props => [uid];
}

class AddFriendEvent extends ProfileEvent {
  final String uid;
  final String friendsUid;
  AddFriendEvent({required this.uid, required this.friendsUid});

  @override
  List<Object> get props => [uid, friendsUid];
}

class RemoveFriendEvent extends ProfileEvent {
  final String uid;
  final String friendsUid;
  RemoveFriendEvent({required this.uid, required this.friendsUid});

  @override
  List<Object> get props => [uid, friendsUid];
}

class ChangeAvatarEvent extends ProfileEvent {
  final String uid;
  final String photoBase64;

  ChangeAvatarEvent(this.uid, this.photoBase64);

  @override
  List<Object> get props => [uid, photoBase64];
}
