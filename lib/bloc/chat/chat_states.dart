import '../../data/models/chat.dart';
import '../../data/models/message.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class UserChatsLoading extends ChatState {}

class UserChatsLoaded extends ChatState {
  final List<Chat> chats;
  UserChatsLoaded(this.chats);
}

class MessagesLoading extends ChatState {}

class MessagesLoaded extends ChatState {
  final List<Message> messages;
  MessagesLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
