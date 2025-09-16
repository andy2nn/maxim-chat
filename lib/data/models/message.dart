class Message {
  final String text;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final String chatId;

  Message({
    required this.text,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.chatId,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'chatId': chatId,
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      chatId: map['chatId'],
    );
  }
}
