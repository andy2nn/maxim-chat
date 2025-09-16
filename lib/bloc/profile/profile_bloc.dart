import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxim_chat/bloc/profile/profile_events.dart';
import 'package:maxim_chat/bloc/profile/profile_states.dart';
import 'package:maxim_chat/data/models/user.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AppRepository appRepository;

  ProfileBloc({required this.appRepository}) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<EditProfileEvent>(_onEditProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<CancelEditEvent>(_onCancelEdit);
    on<ChangeAvatarEvent>(_onChangeAvatar);
    on<AddFriendEvent>(_addFriend);
    on<RemoveFriendEvent>(_removeFriend);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final userStream = appRepository.userStream(event.uid);

      await for (final user in userStream) {
        if (user != null) {
          emit(ProfileLoaded(user: user, isCurrentUser: event.isCurrentUser));
        } else {
          emit(const ProfileError(errorMessage: "User not found"));
        }
        break;
      }
    } catch (e) {
      emit(ProfileError(errorMessage: e.toString()));
    }
  }

  void _onEditProfile(EditProfileEvent event, Emitter<ProfileState> emit) {
    emit(ProfileEditMode(event.user));
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentUser = await _getUser(event.userId);
      if (currentUser == null) {
        emit(const ProfileError(errorMessage: 'User not found'));
        return;
      }

      final updatedUser = currentUser.copyWith(
        username: event.username ?? currentUser.username,
        email: event.email ?? currentUser.email,
        photoBase64: event.photoBase64 ?? currentUser.photoBase64,
      );

      await appRepository.updateUser(updatedUser);

      emit(ProfileUpdated(user: updatedUser));
      emit(ProfileLoaded(user: updatedUser, isCurrentUser: true));
    } catch (e) {
      emit(ProfileError(errorMessage: e.toString()));
    }
  }

  void _onCancelEdit(CancelEditEvent event, Emitter<ProfileState> emit) {
    if (state is ProfileLoaded) {
      emit(state);
    } else {
      emit(ProfileInitial());
    }
  }

  Future<void> _onChangeAvatar(
    ChangeAvatarEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentUser = await _getUser(event.uid);
      if (currentUser == null) {
        emit(const ProfileError(errorMessage: 'User not found'));
        return;
      }

      final updatedUser = currentUser.copyWith(photoBase64: event.photoBase64);

      await appRepository.updateUser(updatedUser);
      emit(ProfileUpdated(user: updatedUser));
      emit(ProfileLoaded(user: updatedUser, isCurrentUser: true));
    } catch (e) {
      emit(ProfileError(errorMessage: e.toString()));
    }
  }

  Future<void> _addFriend(
    AddFriendEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentUser = await _getUser(event.uid);
      final targetUser = await _getUser(event.friendsUid);

      if (currentUser == null || targetUser == null) {
        emit(const ProfileError(errorMessage: 'User not found'));
        return;
      }

      // Используем List вместо Set и создаем новый список
      final updatedCurrentUserFriends = List<String>.from(
        currentUser.friendsUids,
      )..add(event.friendsUid);

      final updatedTargetUserFriends = List<String>.from(targetUser.friendsUids)
        ..add(event.uid);

      final updatedCurrentUser = currentUser.copyWith(
        friendsUids: updatedCurrentUserFriends,
      );

      final updatedTargetUser = targetUser.copyWith(
        friendsUids: updatedTargetUserFriends,
      );

      await appRepository.updateUser(updatedCurrentUser);
      await appRepository.updateUser(updatedTargetUser);

      if (state is ProfileLoaded &&
          (state as ProfileLoaded).user.uid == event.friendsUid) {
        emit(ProfileLoaded(user: updatedTargetUser, isCurrentUser: false));
      }
    } catch (e) {
      emit(ProfileError(errorMessage: e.toString()));
    }
  }

  Future<void> _removeFriend(
    RemoveFriendEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentUser = await _getUser(event.uid);
      final targetUser = await _getUser(event.friendsUid);

      if (currentUser == null || targetUser == null) {
        emit(const ProfileError(errorMessage: 'User not found'));
        return;
      }

      // Создаем новые списки без удаленного друга
      final updatedCurrentUserFriends = List<String>.from(
        currentUser.friendsUids,
      )..remove(event.friendsUid);

      final updatedTargetUserFriends = List<String>.from(targetUser.friendsUids)
        ..remove(event.uid);

      final updatedCurrentUser = currentUser.copyWith(
        friendsUids: updatedCurrentUserFriends,
      );

      final updatedTargetUser = targetUser.copyWith(
        friendsUids: updatedTargetUserFriends,
      );

      await appRepository.updateUser(updatedCurrentUser);
      await appRepository.updateUser(updatedTargetUser);

      if (state is ProfileLoaded &&
          (state as ProfileLoaded).user.uid == event.friendsUid) {
        emit(ProfileLoaded(user: updatedTargetUser, isCurrentUser: false));
      }
    } catch (e) {
      emit(ProfileError(errorMessage: e.toString()));
    }
  }

  Future<User?> _getUser(String userId) async {
    final userStream = appRepository.userStream(userId);
    return userStream.first;
  }
}
