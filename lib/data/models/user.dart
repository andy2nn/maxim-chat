import 'dart:convert';

import 'package:flutter/foundation.dart';

class User {
  final String uid;
  final String email;
  final String username;
  final List<String> friendsUids;
  final List<String> friendsRequests;
  final List<String> friendsSendsRequests;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final String? photoBase64;

  User({
    required this.uid,
    required this.email,
    required this.username,
    this.friendsUids = const [],
    this.friendsRequests = const [],
    this.friendsSendsRequests = const [],
    this.createdAt,
    this.lastSeen,
    this.photoBase64,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      friendsUids: List<String>.from(
        map['friendsUids'] as List<dynamic>? ?? [],
      ),
      friendsRequests: List<String>.from(
        map['friendsRequests'] as List<dynamic>? ?? [],
      ),
      friendsSendsRequests: List<String>.from(
        map['friendsSendsRequests'] as List<dynamic>? ?? [],
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'] as String)
          : null,
      photoBase64: map['photoBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'friendsUids': friendsUids,
      'friendsRequests': friendsRequests,
      'friendsSendsRequests': friendsSendsRequests,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'photoBase64': photoBase64,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? username,
    List<String>? friendsUids,
    List<String>? friendsRequests,
    List<String>? friendsSendsRequests,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? photoBase64,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      friendsUids: friendsUids ?? this.friendsUids,
      friendsRequests: friendsRequests ?? this.friendsRequests,
      friendsSendsRequests: friendsSendsRequests ?? this.friendsSendsRequests,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, username: $username, friendsUids: $friendsUids, friendsRequests: $friendsRequests, friendsSendsRequests: $friendsSendsRequests, createdAt: $createdAt, lastSeen: $lastSeen, photoBase64: $photoBase64)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.email == email &&
        other.username == username &&
        listEquals(other.friendsUids, friendsUids) &&
        listEquals(other.friendsRequests, friendsRequests) &&
        listEquals(other.friendsSendsRequests, friendsSendsRequests) &&
        other.createdAt == createdAt &&
        other.lastSeen == lastSeen &&
        other.photoBase64 == photoBase64;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        username.hashCode ^
        friendsUids.hashCode ^
        friendsRequests.hashCode ^
        friendsSendsRequests.hashCode ^
        createdAt.hashCode ^
        lastSeen.hashCode ^
        photoBase64.hashCode;
  }
}
