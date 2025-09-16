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
}
