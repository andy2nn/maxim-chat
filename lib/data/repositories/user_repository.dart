import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('users');

  Future<void> createUser(User user) async {
    await _db.child(user.uid).set(user.toMap());
  }

  Future<User?> getUser(String uid) async {
    final snapshot = await _db.child(uid).get();
    if (snapshot.exists) {
      return User.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    await _db.child(user.uid).update(user.toMap());
  }

  Stream<User?> userStream(String uid) {
    return _db.child(uid).onValue.map((event) {
      if (event.snapshot.value != null) {
        return User.fromMap(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return null;
    });
  }

  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    final batch = <String, dynamic>{};

    batch['$fromUid/friendsSendsRequests'] = [
      ...await _getFriendSendsRequests(fromUid),
      toUid,
    ];

    batch['$toUid/friendsRequests'] = [
      ...await _getFriendRequests(toUid),
      fromUid,
    ];

    await _db.update(batch);
  }

  Future<void> acceptFriendRequest(
    String acceptorUid,
    String requesterUid,
  ) async {
    final batch = <String, dynamic>{};

    final acceptorRequests = await _getFriendRequests(acceptorUid);
    acceptorRequests.remove(requesterUid);
    batch['$acceptorUid/friendsRequests'] = acceptorRequests;

    final requesterSends = await _getFriendSendsRequests(requesterUid);
    requesterSends.remove(acceptorUid);
    batch['$requesterUid/friendsSendsRequests'] = requesterSends;

    batch['$acceptorUid/friendsUids'] = [
      ...await _getFriends(acceptorUid),
      requesterUid,
    ];
    batch['$requesterUid/friendsUids'] = [
      ...await _getFriends(requesterUid),
      acceptorUid,
    ];

    await _db.update(batch);
  }

  Future<void> rejectFriendRequest(
    String rejectorUid,
    String requesterUid,
  ) async {
    final batch = <String, dynamic>{};

    final rejectorRequests = await _getFriendRequests(rejectorUid);
    rejectorRequests.remove(requesterUid);
    batch['$rejectorUid/friendsRequests'] = rejectorRequests;

    final requesterSends = await _getFriendSendsRequests(requesterUid);
    requesterSends.remove(rejectorUid);
    batch['$requesterUid/friendsSendsRequests'] = requesterSends;

    await _db.update(batch);
  }

  Future<void> removeFriend(String uid1, String uid2) async {
    final batch = <String, dynamic>{};

    final friends1 = await _getFriends(uid1);
    friends1.remove(uid2);
    batch['$uid1/friendsUids'] = friends1;

    final friends2 = await _getFriends(uid2);
    friends2.remove(uid1);
    batch['$uid2/friendsUids'] = friends2;

    await _db.update(batch);
  }

  Future<void> cancelFriendRequest(String fromUid, String toUid) async {
    final batch = <String, dynamic>{};

    final senderSends = await _getFriendSendsRequests(fromUid);
    senderSends.remove(toUid);
    batch['$fromUid/friendsSendsRequests'] = senderSends;

    final receiverRequests = await _getFriendRequests(toUid);
    receiverRequests.remove(fromUid);
    batch['$toUid/friendsRequests'] = receiverRequests;

    await _db.update(batch);
  }

  Future<List<String>> _getFriends(String uid) async {
    final snapshot = await _db.child('$uid/friendsUids').get();
    return List<String>.from(snapshot.value as List? ?? []);
  }

  Future<List<String>> _getFriendRequests(String uid) async {
    final snapshot = await _db.child('$uid/friendsRequests').get();
    return List<String>.from(snapshot.value as List? ?? []);
  }

  Future<List<String>> _getFriendSendsRequests(String uid) async {
    final snapshot = await _db.child('$uid/friendsSendsRequests').get();
    return List<String>.from(snapshot.value as List? ?? []);
  }

  Stream<List<String>> friendsStream(String uid) {
    return _db.child('$uid/friendsUids').onValue.map((event) {
      return List<String>.from(event.snapshot.value as List? ?? []);
    });
  }

  Stream<List<String>> friendRequestsStream(String uid) {
    return _db.child('$uid/friendsRequests').onValue.map((event) {
      return List<String>.from(event.snapshot.value as List? ?? []);
    });
  }

  Stream<List<String>> friendSendsRequestsStream(String uid) {
    return _db.child('$uid/friendsSendsRequests').onValue.map((event) {
      return List<String>.from(event.snapshot.value as List? ?? []);
    });
  }

  Stream<List<User>> friendsWithDetailsStream(String uid) {
    return friendsStream(uid).asyncMap((friendUids) async {
      final friends = <User>[];
      for (final friendUid in friendUids) {
        final friend = await getUser(friendUid);
        if (friend != null) {
          friends.add(friend);
        }
      }
      return friends;
    });
  }

  Stream<List<User>> searchUsers(String query) {
    return _db.onValue.map((event) {
      final users = <User>[];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((uid, userData) {
          final user = User.fromMap(Map<String, dynamic>.from(userData as Map));
          if (user.username.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase())) {
            users.add(user);
          }
        });
      }
      return users;
    });
  }
}
