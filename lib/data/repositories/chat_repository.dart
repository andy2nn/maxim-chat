import 'package:firebase_database/firebase_database.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference get db => _db;

  String _getChatId(List<String> uids) {
    final sortedIds = [...uids]..sort();
    return sortedIds.join("_");
  }

  Future<void> sendMessage(Message message) async {
    final chatRef = _db.child('chats').child(message.chatId).push();
    await chatRef.set(message.toMap());

    for (var uid in message.chatMembers) {
      await _db.child('chats_metadata').child(uid).child(message.chatId).set({
        'lastMessage': message.text,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'members': message.chatMembers,
        'id': message.chatId,
        'isGroup': message.chatName != null,
        'name': message.chatName ?? '',
      });
    }
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _db
        .child('chats')
        .child(chatId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data != null && data is Map) {
            final messages = <Message>[];
            data.forEach((key, value) {
              if (value is Map) {
                messages.add(Message.fromMap(Map<String, dynamic>.from(value)));
              }
            });
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            return messages;
          }
          return <Message>[];
        });
  }

  Future<Chat> createChat(
    List<String> members, {
    String name = '',
    bool isGroup = false,
  }) async {
    final chatId = _getChatId(members);
    final chat = Chat(
      id: chatId,
      members: members,
      name: name,
      isGroup: isGroup,
    );

    final path = isGroup ? 'group_chats' : 'chats';
    final snapshot = await _db.child(path).child(chatId).get();

    if (!snapshot.exists) {
      await _db.child(path).child(chatId).set(chat.toMap());
      for (var uid in members) {
        await _db.child('chats_metadata').child(uid).child(chatId).set({
          'lastMessage': null,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'members': members,
          'id': chatId,
          'isGroup': isGroup,
          'name': name,
        });
      }
    }

    return chat;
  }

  Stream<List<Chat>> getUserChats(String userId) {
    return _db
        .child('chats_metadata')
        .child(userId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data != null && data is Map) {
            final chats = <Chat>[];
            data.forEach((key, value) {
              if (value is Map) {
                chats.add(Chat.fromMap(Map<String, dynamic>.from(value)));
              }
            });
            return chats;
          }
          return <Chat>[];
        });
  }
}
