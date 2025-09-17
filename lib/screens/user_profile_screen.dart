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
        appBar: AppBar(
          title: const Text('Профиль'),
          actions: [
            if (isCurrentUser)
              IconButton(
                icon: const Icon(Icons.logout),
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
        } else if (state is ProfileError) {
          return Center(child: Text('Ошибка: ${state.errorMessage}'));
        } else if (state is ProfileLoaded) {
          return _buildProfileContent(context, state.user, state.isCurrentUser);
        } else if (state is ProfileEditMode) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              border: Border.all(color: Colors.blue, width: 2),
            ),
            width: 200,
            height: 200,
            child: user.photoBase64 != null
                ? ClipOval(
                    child: Image.memory(
                      base64.decode(user.photoBase64!),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text(
            user.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(user.email, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Друзья', user.friendsUids.length),
              _buildStatItem('Запросы', user.friendsRequests.length),
              _buildStatItem('Отправленные', user.friendsSendsRequests.length),
            ],
          ),
          const SizedBox(height: 30),

          if (isCurrentUser)
            ElevatedButton(
              onPressed: () {
                context.read<ProfileBloc>().add(EditProfileEvent(user: user));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text("Редактировать профиль"),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final currentUserId = context.read<AppRepository>().userId;
                    if (currentUserId == null) return;

                    final chatRepo = context
                        .read<AppRepository>()
                        .chatRepository;

                    final members = [currentUserId, user.uid];
                    members.sort();
                    final chatId = members.join('_');

                    final chatExistsSnapshot = await chatRepo.db
                        .child('chats')
                        .child(chatId)
                        .get();

                    late Chat chat;
                    if (chatExistsSnapshot.exists) {
                      chat = Chat.fromMap(
                        Map<String, dynamic>.from(
                          chatExistsSnapshot.value as Map,
                        ),
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
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chat: chat,
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Чат"),
                ),

                if (user.friendsUids.contains(
                  context.read<AppRepository>().userId,
                ))
                  ElevatedButton(
                    onPressed: () {
                      final currentUserId = context
                          .read<AppRepository>()
                          .userId;
                      if (currentUserId != null) {
                        context.read<FriendsBloc>().add(
                          RemoveFriendEvent(currentUserId, user.uid),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Удалить друга"),
                  )
                else if (user.friendsRequests.contains(
                  context.read<AppRepository>().userId,
                ))
                  const ElevatedButton(
                    onPressed: null,
                    child: Text("Запрос отправлен"),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      final currentUserId = context
                          .read<AppRepository>()
                          .userId;
                      if (currentUserId != null) {
                        context.read<FriendsBloc>().add(
                          SendFriendRequestEvent(currentUserId, user.uid),
                        );
                      }
                    },
                    child: const Text("Добавить друга"),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context, User user) {
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);

    return Padding(
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
