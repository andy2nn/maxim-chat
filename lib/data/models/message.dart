class Message {
  final String text;
  final String senderId;
  final String? receiverId;
  final List<String> chatMembers;
  final String chatId;
  final String? chatName;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.senderId,
    this.receiverId,
    required this.chatId,
    required this.chatMembers,
    this.chatName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'chatMembers': chatMembers,
      'chatName': chatName,
      'chatId': chatId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'],
      chatMembers: map['chatMembers'] != null
          ? List<String>.from(map['chatMembers'])
          : [],
      chatName: map['chatName'],
      chatId: map['chatId'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }
}
