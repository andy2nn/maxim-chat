import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxim_chat/bloc/chat/chat_bloc.dart';
import 'package:maxim_chat/bloc/chat/chat_event.dart';
import 'package:maxim_chat/bloc/chat/chat_states.dart';
import '../data/repositories/app_repository.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AppRepository>().userId!;

    // Загружаем чаты
    context.read<ChatBloc>().add(LoadUserChats(currentUserId));

    return Scaffold(
      appBar: AppBar(title: const Text('Чаты')),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is UserChatsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UserChatsLoaded) {
            final chats = state.chats;
            if (chats.isEmpty) {
              return const Center(child: Text('Нет чатов'));
            }

            // Сортировка по последнему сообщению
            chats.sort((a, b) {
              final t1 =
                  a.lastMessageTimestamp ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final t2 =
                  b.lastMessageTimestamp ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return t2.compareTo(t1);
            });

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherMembers = chat.members
                    .where((id) => id != currentUserId)
                    .toList();
                final chatTitle = chat.isGroup
                    ? chat.name.isNotEmpty
                          ? chat.name
                          : 'Группа'
                    : otherMembers.isNotEmpty
                    ? otherMembers.first
                    : 'Неизвестный пользователь';

                final avatarColor = chat.isGroup ? Colors.red : Colors.blue;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarColor,
                    child: chat.isGroup
                        ? Text(
                            chat.name.isNotEmpty
                                ? chat.name[0].toUpperCase()
                                : 'G',
                          )
                        : null, // Для обычного чата можно потом подставить аватарку пользователя
                  ),
                  title: Text(chatTitle),
                  subtitle: Text(
                    chat.lastMessage ?? 'Нет сообщений',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(chat: chat, currentUserId: currentUserId),
                    ),
                  ),
                );
              },
            );
          }
          if (state is ChatError) return Center(child: Text(state.message));

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContactsScreen(
              onSelect: (selectedUsers) async {
                if (selectedUsers.isEmpty) return;

                final repo = context.read<AppRepository>();
                final isGroup = selectedUsers.length > 1;
                final members = selectedUsers.map((u) => u.uid).toList();

                // Для группы можно предложить ввести название через диалог
                String name = '';
                if (isGroup) {
                  name = await _showGroupNameDialog(context) ?? 'Группа';
                }

                // Создаем чат
                final chat = await repo.createChat(
                  members,
                  name: name,
                  isGroup: isGroup,
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chat: chat,
                      currentUserId: context.read<AppRepository>().userId!,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showGroupNameDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название группы'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите название группы',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
