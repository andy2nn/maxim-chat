import '../../data/models/message.dart';

abstract class ChatEvent {}

class LoadUserChats extends ChatEvent {
  final String userId;
  LoadUserChats(this.userId);
}

class SendMessageEvent extends ChatEvent {
  final Message message;
  SendMessageEvent(this.message);
}

class LoadMessagesEvent extends ChatEvent {
  final String chatId;
  LoadMessagesEvent(this.chatId);
}

class CreateGroupChatEvent extends ChatEvent {
  final String name;
  final List<String> members;
  CreateGroupChatEvent(this.name, this.members);
}
