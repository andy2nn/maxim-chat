import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';

class ChatRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String _getChatId(String uid1, String uid2) {
    final sortedIds = [uid1, uid2]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> sendMessage(
    String senderId,
    String receiverId,
    Message message,
  ) async {
    final chatId = _getChatId(senderId, receiverId);
    final chatRef = _db.child('chats').child(chatId).push();
    await chatRef.set(message.toMap());

    await _db.child('user_chats').child(senderId).child(chatId).set({
      'lastMessage': message.text,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'receiverId': receiverId,
    });

    await _db.child('user_chats').child(receiverId).child(chatId).set({
      'lastMessage': message.text,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'receiverId': senderId,
    });
  }

  Stream<List<Message>> getMessages(String uid1, String uid2) {
    final chatId = _getChatId(uid1, uid2);
    return _db
        .child('chats')
        .child(chatId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data != null) {
            final map = Map<String, dynamic>.from(data as Map);
            return map.entries.map((e) {
              return Message.fromMap(Map<String, dynamic>.from(e.value));
            }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          }
          return [];
        });
  }

  Stream<Map<String, dynamic>> getUserChats(String userId) {
    return _db.child('user_chats').child(userId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data != null) {
        return Map<String, dynamic>.from(data as Map);
      }
      return {};
    });
  }

  Future<void> createChat(String uid1, String uid2) async {
    final chatId = _getChatId(uid1, uid2);

    await _db.child('user_chats').child(uid1).child(chatId).set({
      'receiverId': uid2,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    await _db.child('user_chats').child(uid2).child(chatId).set({
      'receiverId': uid1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
