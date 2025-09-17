import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_states.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<LoadUserChats>((event, emit) async {
      emit(UserChatsLoading());
      await _chatsSubscription?.cancel();
      _chatsSubscription = chatRepository
          .getUserChats(event.userId)
          .listen((chats) => add(_UserChatsUpdated(chats)));
    });

    on<_UserChatsUpdated>((event, emit) => emit(UserChatsLoaded(event.chats)));

    on<LoadMessagesEvent>((event, emit) async {
      emit(MessagesLoading());
      await _messagesSubscription?.cancel();
      _messagesSubscription = chatRepository
          .getMessages(event.chatId)
          .listen((messages) => add(_MessagesUpdated(messages)));
    });

    on<_MessagesUpdated>((event, emit) => emit(MessagesLoaded(event.messages)));

    on<SendMessageEvent>((event, emit) async {
      await chatRepository.sendMessage(event.message);
    });

    on<CreateGroupChatEvent>((event, emit) async {
      await chatRepository.createChat(
        event.members,
        name: event.name,
        isGroup: true,
      );
    });
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}

class _UserChatsUpdated extends ChatEvent {
  final List<Chat> chats;
  _UserChatsUpdated(this.chats);
}

class _MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  _MessagesUpdated(this.messages);
}
