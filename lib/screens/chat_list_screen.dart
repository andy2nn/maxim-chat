import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat/chat_bloc.dart';
import '../bloc/chat/chat_event.dart';
import '../bloc/chat/chat_states.dart';
import '../bloc/friends/friends_bloc.dart';
import '../bloc/friends/friends_events.dart';
import '../bloc/friends/friends_states.dart';
import '../data/models/user.dart';
import '../data/repositories/app_repository.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AppRepository>().userId!;
    context.read<ChatBloc>().add(LoadUserChats(currentUserId));
    context.read<FriendsBloc>().add(LoadFriendsEvent(currentUserId));

    return Scaffold(
      appBar: AppBar(title: const Text('Чаты')),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, chatState) {
          if (chatState is UserChatsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<FriendsBloc, FriendsState>(
            builder: (context, friendsState) {
              final friends = (friendsState is FriendsLoaded)
                  ? friendsState.friends
                  : <User>[];

              if (chatState is UserChatsLoaded) {
                final chats = chatState.chats;
                if (chats.isEmpty) {
                  return const Center(child: Text('Нет чатов'));
                }

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
                        ? (chat.name.isNotEmpty ? chat.name : 'Группа')
                        : (otherMembers.isNotEmpty
                              ? otherMembers.first
                              : 'Неизвестный пользователь');
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
                            : null,
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
                          builder: (_) => ChatScreen(
                            chat: chat,
                            currentUserId: currentUserId,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              if (chatState is ChatError) {
                return Center(child: Text(chatState.message));
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<FriendsBloc, FriendsState>(
        builder: (context, friendsState) {
          final friends = (friendsState is FriendsLoaded)
              ? friendsState.friends
              : <User>[];
          if (friends.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContactsScreen(
                  friends: friends,
                  onSelect: (selectedUsers, String? groupName) async {
                    if (selectedUsers.isEmpty) return;

                    final repo = context.read<AppRepository>();
                    final isGroup = selectedUsers.length > 1;
                    final members = selectedUsers.map((u) => u.uid).toList();
                    final name = isGroup ? (groupName ?? 'Группа') : '';

                    final chat = await repo.createChat(
                      members,
                      name: name,
                      isGroup: isGroup,
                    );

                    Navigator.pushReplacement(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chat: chat,
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
