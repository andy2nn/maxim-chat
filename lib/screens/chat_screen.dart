import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat/chat_bloc.dart';
import '../bloc/chat/chat_event.dart';
import '../bloc/chat/chat_states.dart';
import '../data/models/chat.dart';
import '../data/models/message.dart';
import '../screens/user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadMessagesEvent(widget.chat.id));
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = Message(
      text: text,
      senderId: widget.currentUserId,
      chatId: widget.chat.id,
      chatMembers: widget.chat.members,
      timestamp: DateTime.now(),
      chatName: widget.chat.isGroup ? widget.chat.name : null,
    );

    context.read<ChatBloc>().add(SendMessageEvent(message));
    _controller.clear();
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId, isCurrentUser: false),
      ),
    );
  }

  Widget _buildMessageItem(Message msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                )
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade200],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: GestureDetector(
          onTap: () {
            if (!chat.isGroup && chat.members.length == 2) {
              final otherUserId = chat.members.firstWhere(
                (id) => id != widget.currentUserId,
                orElse: () => chat.members.first,
              );
              _openProfile(otherUserId);
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade200,
                child: chat.isGroup
                    ? Text(chat.name.isNotEmpty ? chat.name[0] : 'G')
                    : const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  chat.isGroup ? chat.name : 'Чат с пользователем',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is MessagesLoaded) {
                    _messages = state.messages.reversed.toList();
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  if (state is MessagesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_messages.isEmpty) {
                    return const Center(child: Text('Нет сообщений'));
                  }
                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildMessageItem(msg, isMe);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
