import 'package:maxim_chat/data/models/user.dart';

abstract class FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final List<User> friends;
  final List<User> friendRequests;
  final List<User> sentRequests;
  final List<User> searchResults;

  FriendsLoaded({
    required this.friends,
    required this.friendRequests,
    required this.sentRequests,
    required this.searchResults,
  });
}

class FriendsError extends FriendsState {
  final String message;

  FriendsError(this.message);
}
