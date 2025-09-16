import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxim_chat/bloc/profile/profile_bloc.dart';
import 'package:maxim_chat/bloc/profile/profile_events.dart';
import 'package:maxim_chat/bloc/profile/profile_states.dart';
import 'package:maxim_chat/data/models/user.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/main.dart';

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

    return BlocProvider(
      create: (context) => ProfileBloc(
        appRepository: context.read<AppRepository>(),
      )..add(LoadProfileEvent(uid: targetUserId, isCurrentUser: isCurrentUser)),
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
        content: const Text('Вы уверены что хотите выйти ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отменв'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          Text(
            user.email,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Друзья', user.friendsUids.length),
              _buildStatItem('Запросы', user.friendsRequests.length),
              _buildStatItem(
                'Отправленные запросы',
                user.friendsSendsRequests.length,
              ),
            ],
          ),
          const SizedBox(height: 30),

          if (isCurrentUser) ...[
            ElevatedButton(
              onPressed: () {
                context.read<ProfileBloc>().add(EditProfileEvent(user: user));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text("Редактировать профиль"),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    //TODO(Artem): Написать логику перехда к чату пользователя
                    Navigator.pushNamed(context, '/chat', arguments: user.uid);
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
                        context.read<ProfileBloc>().add(
                          RemoveFriendEvent(
                            uid: currentUserId,
                            friendsUid: user.uid,
                          ),
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
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Request Sent"),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      final currentUserId = context
                          .read<AppRepository>()
                          .userId;
                      if (currentUserId != null) {
                        context.read<ProfileBloc>().add(
                          AddFriendEvent(
                            uid: currentUserId,
                            friendsUid: user.uid,
                          ),
                        );
                      }
                    },
                    child: const Text("Добавить друга"),
                  ),
              ],
            ),
          ],

          if (user.createdAt != null) ...[
            const SizedBox(height: 30),
            Text(
              'Пользователь с  ${_formatDate(user.createdAt!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                border: Border.all(color: Colors.blue, width: 2),
              ),
              width: 150,
              height: 150,
              child: user.photoBase64 != null
                  ? ClipOval(
                      child: Image.memory(
                        base64.decode(user.photoBase64!),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
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
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<ProfileBloc>().add(CancelEditEvent());
                },
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
    //TODO(artem): Здесь можно добавить логику выбора изображения из галереи или камеры
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Avatar'),
        content: const Text('Choose image source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Логика выбора из галереи
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Логика съемки фото
            },
            child: const Text('Camera'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Назад'),
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
