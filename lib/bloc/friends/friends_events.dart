abstract class FriendsEvent {}

class LoadFriendsEvent extends FriendsEvent {
  final String userId;

  LoadFriendsEvent(this.userId);
}

class SearchUsersEvent extends FriendsEvent {
  final String query;

  SearchUsersEvent(this.query);
}

class SendFriendRequestEvent extends FriendsEvent {
  final String fromUid;
  final String toUid;

  SendFriendRequestEvent(this.fromUid, this.toUid);
}

class AcceptFriendRequestEvent extends FriendsEvent {
  final String acceptorUid;
  final String requesterUid;

  AcceptFriendRequestEvent(this.acceptorUid, this.requesterUid);
}

class RejectFriendRequestEvent extends FriendsEvent {
  final String rejectorUid;
  final String requesterUid;

  RejectFriendRequestEvent(this.rejectorUid, this.requesterUid);
}

class RemoveFriendEvent extends FriendsEvent {
  final String uid1;
  final String uid2;

  RemoveFriendEvent(this.uid1, this.uid2);
}

class CancelFriendRequestEvent extends FriendsEvent {
  final String fromUid;
  final String toUid;

  CancelFriendRequestEvent(this.fromUid, this.toUid);
}
