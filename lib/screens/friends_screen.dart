import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxim_chat/bloc/friends/friends_bloc.dart';
import 'package:maxim_chat/bloc/friends/friends_events.dart';
import 'package:maxim_chat/bloc/friends/friends_states.dart';
import 'package:maxim_chat/data/models/user.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';
import 'package:maxim_chat/screens/user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  final String? userId;

  const FriendsScreen({super.key, this.userId});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userId ?? context.read<AppRepository>().userId;

    return BlocProvider(
      create: (context) => FriendsBloc(
        appRepository: context.read<AppRepository>(),
        currentUserId: currentUserId!,
      )..add(LoadFriendsEvent(currentUserId)),
      child: Builder(
        builder: (innerContext) {
          void onSearchChanged(String query) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 500), () {
              innerContext.read<FriendsBloc>().add(SearchUsersEvent(query));
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Друзья'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Друзья'),
                  Tab(text: 'Запросы'),
                  Tab(text: 'Отправленные'),
                ],
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск пользователей...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                Expanded(
                  child: BlocConsumer<FriendsBloc, FriendsState>(
                    listener: (context, state) {
                      if (state is FriendsError) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(state.message)));
                      }
                    },
                    builder: (context, state) {
                      if (state is FriendsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is FriendsError) {
                        return Center(child: Text(state.message));
                      }

                      if (state is FriendsLoaded) {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildFriendsList(
                              innerContext,
                              state.friends,
                              state.searchResults,
                            ),
                            _buildRequestsList(
                              innerContext,
                              state.friendRequests,
                              state.searchResults,
                            ),
                            _buildSentRequestsList(
                              innerContext,
                              state.sentRequests,
                              state.searchResults,
                            ),
                          ],
                        );
                      }

                      return const Center(child: Text('Нет данных'));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    List<User> friends,
    List<User> searchResults,
  ) {
    final displayList = searchResults.isNotEmpty ? searchResults : friends;

    if (displayList.isEmpty) {
      return const Center(child: Text('Нет друзей'));
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final user = displayList[index];
        return _buildUserTile(context, user, isFriend: true);
      },
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    List<User> requests,
    List<User> searchResults,
  ) {
    final displayList = searchResults.isNotEmpty ? searchResults : requests;

    if (displayList.isEmpty) {
      return const Center(child: Text('Нет входящих запросов'));
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final user = displayList[index];
        return _buildRequestTile(context, user);
      },
    );
  }

  Widget _buildSentRequestsList(
    BuildContext context,
    List<User> sentRequests,
    List<User> searchResults,
  ) {
    final displayList = searchResults.isNotEmpty ? searchResults : sentRequests;

    if (displayList.isEmpty) {
      return const Center(child: Text('Нет отправленных запросов'));
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final user = displayList[index];
        return _buildSentRequestTile(context, user);
      },
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    User user, {
    bool isFriend = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoBase64 != null
            ? MemoryImage(_decodeBase64(user.photoBase64!))
            : null,
        child: user.photoBase64 == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.username),
      subtitle: Text(user.email),
      trailing: isFriend
          ? IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.red),
              onPressed: () {
                final currentUserId = context.read<AppRepository>().userId;
                if (currentUserId != null) {
                  context.read<FriendsBloc>().add(
                    RemoveFriendEvent(currentUserId, user.uid),
                  );
                }
              },
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                UserProfileScreen(userId: user.uid, isCurrentUser: false),
          ),
        );
      },
    );
  }

  Widget _buildRequestTile(BuildContext context, User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoBase64 != null
            ? MemoryImage(_decodeBase64(user.photoBase64!))
            : null,
        child: user.photoBase64 == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.username),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              final currentUserId = context.read<AppRepository>().userId;
              if (currentUserId != null) {
                context.read<FriendsBloc>().add(
                  AcceptFriendRequestEvent(currentUserId, user.uid),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              final currentUserId = context.read<AppRepository>().userId;
              if (currentUserId != null) {
                context.read<FriendsBloc>().add(
                  RejectFriendRequestEvent(currentUserId, user.uid),
                );
              }
            },
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                UserProfileScreen(userId: user.uid, isCurrentUser: false),
          ),
        );
      },
    );
  }

  Widget _buildSentRequestTile(BuildContext context, User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoBase64 != null
            ? MemoryImage(_decodeBase64(user.photoBase64!))
            : null,
        child: user.photoBase64 == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.username),
      subtitle: Text(user.email),
      trailing: IconButton(
        icon: const Icon(Icons.cancel, color: Colors.orange),
        onPressed: () {
          final currentUserId = context.read<AppRepository>().userId;
          if (currentUserId != null) {
            context.read<FriendsBloc>().add(
              CancelFriendRequestEvent(currentUserId, user.uid),
            );
          }
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                UserProfileScreen(userId: user.uid, isCurrentUser: false),
          ),
        );
      },
    );
  }

  Uint8List _decodeBase64(String base64String) => base64.decode(base64String);
}
