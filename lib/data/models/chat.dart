class Chat {
  final String id;
  final String name;
  final List<String> members;
  final bool isGroup;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;

  Chat({
    required this.id,
    required this.members,
    this.name = '',
    this.isGroup = false,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'members': members,
    'isGroup': isGroup,
    'lastMessage': lastMessage,
    'lastMessageTimestamp': lastMessageTimestamp?.millisecondsSinceEpoch,
  };

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      members: map['members'] != null ? List<String>.from(map['members']) : [],
      isGroup: map['isGroup'] ?? false,
      lastMessage: map['lastMessage'],
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTimestamp'])
          : null,
    );
  }
}
