import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat/chat_bloc.dart';
import '../bloc/chat/chat_event.dart';
import '../bloc/chat/chat_states.dart';
import '../bloc/friends/friends_bloc.dart';
import '../bloc/friends/friends_events.dart';
import '../bloc/friends/friends_states.dart';
import '../data/models/user.dart';
import '../data/models/chat.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: isWeb
                  ? _WebLayout(currentUserId: currentUserId)
                  : _MobileLayout(currentUserId: currentUserId),
            ),
          ),
          floatingActionButton: isWeb
              ? null
              : _NewChatButton(currentUserId: currentUserId),
        );
      },
    );
  }
}

// ===================== MOBILE LAYOUT =====================
class _MobileLayout extends StatelessWidget {
  final String currentUserId;
  const _MobileLayout({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScreenAppBar(title: "Мои чаты", icon: Icons.chat_bubble_outline),
        Expanded(
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is UserChatsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is UserChatsLoaded) {
                final chats = state.chats;
                if (chats.isEmpty) {
                  return const Center(child: Text('У вас пока нет чатов 🙃'));
                }
                chats.sort(
                  (a, b) =>
                      (b.lastMessageTimestamp ??
                              DateTime.fromMillisecondsSinceEpoch(0))
                          .compareTo(
                            a.lastMessageTimestamp ??
                                DateTime.fromMillisecondsSinceEpoch(0),
                          ),
                );
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherMembers = chat.members
                        .where((id) => id != currentUserId)
                        .toList();
                    final title = chat.isGroup
                        ? (chat.name.isNotEmpty ? chat.name : 'Группа')
                        : (otherMembers.isNotEmpty
                              ? otherMembers.first
                              : 'Неизвестный пользователь');
                    return ChatCard(
                      title: title,
                      subtitle: chat.lastMessage ?? 'Нет сообщений',
                      isGroup: chat.isGroup,
                      time: chat.lastMessageTimestamp,
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
              if (state is ChatError) return Center(child: Text(state.message));
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

// ===================== WEB LAYOUT =====================
class _WebLayout extends StatefulWidget {
  final String currentUserId;
  const _WebLayout({required this.currentUserId});

  @override
  State<_WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<_WebLayout> {
  Chat? _selectedChat;

  void _selectChat(Chat chat) {
    setState(() {
      _selectedChat = chat;
    });
    context.read<ChatBloc>().add(LoadMessagesEvent(chat.id));
  }

  void _createNewChat(List<User> selectedUsers, String? groupName) async {
    if (selectedUsers.isEmpty) return;

    final repo = context.read<AppRepository>();
    final isGroup = selectedUsers.length > 1;
    final members = selectedUsers.map((u) => u.uid).toList();
    final name = isGroup ? (groupName ?? 'Группа') : '';

    final newChat = await repo.createChat(
      members,
      name: name,
      isGroup: isGroup,
    );

    // ignore: use_build_context_synchronously
    context.read<ChatBloc>().add(LoadUserChats(widget.currentUserId));

    setState(() {
      _selectedChat = newChat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _ScreenAppBar(title: "Мои чаты", icon: Icons.chat_bubble_outline),
              Expanded(
                child: _ChatList(
                  currentUserId: widget.currentUserId,
                  onSelectChat: _selectChat,
                  selectedChat: _selectedChat,
                ),
              ),
              BlocBuilder<FriendsBloc, FriendsState>(
                builder: (context, friendsState) {
                  final friends = (friendsState is FriendsLoaded)
                      ? friendsState.friends
                      : <User>[];
                  if (friends.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text("Новый чат"),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContactsScreen(
                              friends: friends,
                              onSelect:
                                  (
                                    List<User> selectedUsers,
                                    String? groupName,
                                  ) async {
                                    Navigator.pop(context, {
                                      'users': selectedUsers,
                                      'groupName': groupName,
                                    });
                                  },
                            ),
                          ),
                        );

                        if (result != null && result is Map) {
                          final selectedUsers = result['users'] as List<User>;
                          final groupName = result['groupName'] as String?;
                          _createNewChat(selectedUsers, groupName);
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _selectedChat != null
              ? BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (previous, current) =>
                      current is MessagesLoaded || current is ChatError,
                  builder: (context, state) {
                    return ChatScreen(
                      chat: _selectedChat!,
                      currentUserId: widget.currentUserId,
                    );
                  },
                )
              : Center(
                  child: Text(
                    "Выберите чат слева",
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ChatList extends StatefulWidget {
  final String currentUserId;
  final Function(Chat) onSelectChat;
  final Chat? selectedChat;

  const _ChatList({
    required this.currentUserId,
    required this.onSelectChat,
    this.selectedChat,
  });

  @override
  State<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<_ChatList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (previous, current) =>
          current is UserChatsLoaded || current is ChatError,
      builder: (context, state) {
        if (state is UserChatsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is UserChatsLoaded) {
          final chats = state.chats;
          if (chats.isEmpty) {
            return const Center(child: Text('У вас пока нет чатов 🙃'));
          }

          chats.sort(
            (a, b) =>
                (b.lastMessageTimestamp ??
                        DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(
                      a.lastMessageTimestamp ??
                          DateTime.fromMillisecondsSinceEpoch(0),
                    ),
          );

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherMembers = chat.members
                  .where((id) => id != widget.currentUserId)
                  .toList();
              final title = chat.isGroup
                  ? (chat.name.isNotEmpty ? chat.name : 'Группа')
                  : (otherMembers.isNotEmpty
                        ? otherMembers.first
                        : 'Неизвестный пользователь');

              final isSelected = widget.selectedChat?.id == chat.id;

              return ChatCard(
                title: title,
                subtitle: chat.lastMessage ?? 'Нет сообщений',
                isGroup: chat.isGroup,
                time: chat.lastMessageTimestamp,
                onTap: () => widget.onSelectChat(chat),
                selected: isSelected,
              );
            },
          );
        }
        if (state is ChatError) return Center(child: Text(state.message));
        return const SizedBox.shrink();
      },
    );
  }
}

class _ScreenAppBar extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ScreenAppBar({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  final String currentUserId;
  const _NewChatButton({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, friendsState) {
        final friends = (friendsState is FriendsLoaded)
            ? friendsState.friends
            : <User>[];
        if (friends.isEmpty) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          backgroundColor: Colors.blue.shade600,
          icon: const Icon(Icons.edit),
          label: const Text("Новый чат"),
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
                      builder: (_) =>
                          ChatScreen(chat: chat, currentUserId: currentUserId),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isGroup;
  final DateTime? time;
  final VoidCallback onTap;
  final bool selected;

  const ChatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isGroup,
    this.time,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Colors.blue.shade100 : null,
      elevation: 4,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isGroup ? Colors.red.shade400 : Colors.blue.shade400,
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: time != null
            ? Text(
                _formatTime(time!),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.day}.${time.month}.${time.year}";
  }
}
