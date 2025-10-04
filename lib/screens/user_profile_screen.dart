import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxim_chat/bloc/friends/friends_bloc.dart';
import 'package:maxim_chat/bloc/friends/friends_events.dart';
import 'package:maxim_chat/bloc/profile/profile_bloc.dart';
import 'package:maxim_chat/bloc/profile/profile_events.dart';
import 'package:maxim_chat/bloc/profile/profile_states.dart';
import 'package:maxim_chat/data/models/chat.dart';
import 'package:maxim_chat/data/models/user.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/main.dart';
import 'package:maxim_chat/screens/chat_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String? userId;
  final bool isCurrentUser;

  const UserProfileScreen({super.key, this.userId, this.isCurrentUser = true});

  @override
  Widget build(BuildContext context) {
    final targetUserId = userId ?? context.read<AppRepository>().userId;
    if (targetUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не найден')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ProfileBloc(appRepository: context.read<AppRepository>())..add(
                LoadProfileEvent(
                  uid: targetUserId,
                  isCurrentUser: isCurrentUser,
                ),
              ),
        ),
        BlocProvider(
          create: (context) => FriendsBloc(
            appRepository: context.read<AppRepository>(),
            currentUserId: context.read<AppRepository>().userId!,
          ),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: AppBar(
          backgroundColor: Colors.blue.shade50,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.blue.shade800),
          title: Text(
            'Профиль',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (isCurrentUser)
              IconButton(
                icon: Icon(Icons.logout, color: Colors.blue.shade800),
                onPressed: () => _showLogoutDialog(context),
              ),
          ],
        ),
        body: const _ProfileContent(),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppRepository>().signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                NavigatorNames.checkAuth,
                (route) => false,
              );
            },
            child: const Text('Выход'),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProfileError) {
          return Center(child: Text('Ошибка: ${state.errorMessage}'));
        }
        if (state is ProfileLoaded) {
          return _buildProfileContent(context, state.user, state.isCurrentUser);
        }
        if (state is ProfileEditMode) {
          return _buildEditForm(context, state.user);
        }
        return const Center(child: Text('Данные недоступны'));
      },
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    User user,
    bool isCurrentUser,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    final contentWidth = isWeb ? 600.0 : double.infinity;

    return Center(
      child: Container(
        width: contentWidth,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Аватар с градиентом и тенью
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade500],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isWeb ? 100 : 80,
                backgroundColor: Colors.grey.shade100,
                child: user.photoBase64 != null
                    ? ClipOval(
                        child: Image.memory(
                          base64.decode(user.photoBase64!),
                          width: isWeb ? 200 : 160,
                          height: isWeb ? 200 : 160,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.person, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.username,
              style: TextStyle(
                fontSize: isWeb ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: isWeb ? 16 : 14,
              ),
            ),
            const SizedBox(height: 20),
            // Статистика
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.blue.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      'Друзья',
                      user.friendsUids.length,
                      Colors.blue.shade700,
                    ),
                    _buildStatItem(
                      'Запросы',
                      user.friendsRequests.length,
                      Colors.green.shade700,
                    ),
                    _buildStatItem(
                      'Отправленные',
                      user.friendsSendsRequests.length,
                      Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Кнопки действий
            isCurrentUser
                ? ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(
                      EditProfileEvent(user: user),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Редактировать профиль",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _openChat(context, user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(140, 45),
                        ),
                        child: const Text("Чат"),
                      ),
                      _buildFriendActionButton(context, user),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  void _openChat(BuildContext context, User user) async {
    final currentUserId = context.read<AppRepository>().userId;
    if (currentUserId == null) return;
    final chatRepo = context.read<AppRepository>().chatRepository;
    final members = [currentUserId, user.uid]..sort();
    final chatId = members.join('_');

    final chatExistsSnapshot = await chatRepo.db
        .child('chats')
        .child(chatId)
        .get();
    late Chat chat;
    if (chatExistsSnapshot.exists) {
      chat = Chat.fromMap(
        Map<String, dynamic>.from(chatExistsSnapshot.value as Map),
      );
    } else {
      await chatRepo.createChat(
        [currentUserId, user.uid],
        isGroup: false,
        name: user.username,
      );
      chat = Chat(
        id: chatId,
        members: members,
        isGroup: false,
        name: user.username,
      );
    }

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chat: chat, currentUserId: currentUserId),
      ),
    );
  }

  Widget _buildFriendActionButton(BuildContext context, User user) {
    final currentUserId = context.read<AppRepository>().userId;
    if (currentUserId == null) return const SizedBox.shrink();
    if (user.friendsUids.contains(currentUserId)) {
      return ElevatedButton(
        onPressed: () => context.read<FriendsBloc>().add(
          RemoveFriendEvent(currentUserId, user.uid),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(140, 45),
        ),
        child: const Text("Удалить"),
      );
    } else if (user.friendsRequests.contains(currentUserId)) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(140, 45),
        ),
        child: const Text("Запрос отправлен"),
      );
    } else {
      return ElevatedButton(
        onPressed: () => context.read<FriendsBloc>().add(
          SendFriendRequestEvent(currentUserId, user.uid),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(140, 45),
        ),
        child: const Text("Добавить"),
      );
    }
  }

  Widget _buildEditForm(BuildContext context, User user) {
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _changeAvatar(context, user.uid),
            child: CircleAvatar(
              radius: 75,
              backgroundImage: user.photoBase64 != null
                  ? MemoryImage(base64.decode(user.photoBase64!))
                  : null,
              child: user.photoBase64 == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () =>
                    context.read<ProfileBloc>().add(CancelEditEvent()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  minimumSize: const Size(120, 45),
                ),
                child: const Text('Назад'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ProfileBloc>().add(
                    UpdateProfileEvent(
                      userId: user.uid,
                      username: usernameController.text,
                      email: emailController.text,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  minimumSize: const Size(120, 45),
                ),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _changeAvatar(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сменить аватар'),
        content: const Text('Выберите источник изображения'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Галерея'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Камера'),
          ),
        ],
      ),
    );
  }
}
