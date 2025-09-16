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
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
      friendsUids: List<String>.from(map['friendsUids'] ?? []),
      friendsRequests: List<String>.from(map['friendsRequests'] ?? []),
      friendsSendsRequests: List<String>.from(
        map['friendsSendsRequests'] ?? [],
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'])
          : null,
      photoBase64: map['photoBase64'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'friendsUids': friendsUids,
      'friendsRequests': friendsRequests,
      'friendsSendsRequests': friendsSendsRequests,
      'createdAt': createdAt?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'photoBase64': photoBase64,
    };
  }
}
