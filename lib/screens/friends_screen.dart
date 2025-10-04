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

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 800;
              final avatarRadius = isWeb ? 30.0 : 24.0;
              final cardPadding = isWeb ? 24.0 : 12.0;
              final maxWidth = isWeb ? 1000.0 : double.infinity;

              return Scaffold(
                body: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isWeb
                              ? [Colors.blue.shade100, Colors.blue.shade300]
                              : [Colors.blue.shade50, Colors.blue.shade100],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isWeb
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    color: Colors.blue.shade800,
                                    size: isWeb ? 36 : 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Друзья",
                                    style: TextStyle(
                                      fontSize: isWeb ? 28 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: "Поиск пользователей...",
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.blue.shade800,
                                labelStyle: TextStyle(
                                  fontSize: isWeb ? 16 : 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                unselectedLabelStyle: TextStyle(
                                  fontSize: isWeb ? 15 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                tabs: [
                                  _buildAnimatedTab("Друзья", 0),
                                  _buildAnimatedTab("Запросы", 1),
                                  _buildAnimatedTab("Отправленные", 2),
                                ],
                              ),
                            ),
                            Expanded(
                              child: BlocConsumer<FriendsBloc, FriendsState>(
                                listener: (context, state) {
                                  if (state is FriendsError) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(state.message)),
                                    );
                                  }
                                },
                                builder: (context, state) {
                                  if (state is FriendsLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (state is FriendsLoaded) {
                                    return TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildList(
                                          innerContext,
                                          state.friends,
                                          state.searchResults,
                                          type: "friend",
                                          avatarRadius: avatarRadius,
                                          padding: cardPadding,
                                        ),
                                        _buildList(
                                          innerContext,
                                          state.friendRequests,
                                          state.searchResults,
                                          type: "request",
                                          avatarRadius: avatarRadius,
                                          padding: cardPadding,
                                        ),
                                        _buildList(
                                          innerContext,
                                          state.sentRequests,
                                          state.searchResults,
                                          type: "sent",
                                          avatarRadius: avatarRadius,
                                          padding: cardPadding,
                                        ),
                                      ],
                                    );
                                  }
                                  return const Center(
                                    child: Text("Нет данных"),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAnimatedTab(String text, int index) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        double selectedness = _tabController.index == index ? 1.0 : 0.9;
        return Transform.scale(
          scale: selectedness,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Tab(text: text),
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<User> list,
    List<User> searchResults, {
    required String type,
    double avatarRadius = 24,
    double padding = 12,
  }) {
    final displayList = searchResults.isNotEmpty ? searchResults : list;
    if (displayList.isEmpty) {
      return Center(
        child: Text(
          type == "friend"
              ? "Нет друзей 😔"
              : type == "request"
              ? "Нет входящих запросов 📩"
              : "Нет отправленных запросов 📤",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(padding),
      itemCount: displayList.length,
      separatorBuilder: (_, __) => SizedBox(height: padding),
      itemBuilder: (context, index) {
        final user = displayList[index];
        switch (type) {
          case "friend":
            return _buildFriendCard(
              context,
              user,
              avatarRadius: avatarRadius,
              padding: padding,
            );
          case "request":
            return _buildRequestCard(
              context,
              user,
              avatarRadius: avatarRadius,
              padding: padding,
            );
          case "sent":
            return _buildSentCard(
              context,
              user,
              avatarRadius: avatarRadius,
              padding: padding,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    User user, {
    double avatarRadius = 24,
    double padding = 12,
  }) {
    return _buildUserCard(
      user,
      trailing: IconButton(
        icon: const Icon(Icons.person_remove, color: Colors.red),
        onPressed: () {
          final currentUserId = context.read<AppRepository>().userId;
          if (currentUserId != null) {
            context.read<FriendsBloc>().add(
              RemoveFriendEvent(currentUserId, user.uid),
            );
          }
        },
      ),
      onTap: () => _openProfile(context, user.uid),
      avatarRadius: avatarRadius,
      padding: padding,
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    User user, {
    double avatarRadius = 24,
    double padding = 12,
  }) {
    return _buildUserCard(
      user,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            radius: avatarRadius / 1.5,
            child: IconButton(
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
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            radius: avatarRadius / 1.5,
            child: IconButton(
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
          ),
        ],
      ),
      onTap: () => _openProfile(context, user.uid),
      avatarRadius: avatarRadius,
      padding: padding,
    );
  }

  Widget _buildSentCard(
    BuildContext context,
    User user, {
    double avatarRadius = 24,
    double padding = 12,
  }) {
    return _buildUserCard(
      user,
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
      onTap: () => _openProfile(context, user.uid),
      avatarRadius: avatarRadius,
      padding: padding,
    );
  }

  Widget _buildUserCard(
    User user, {
    required Widget trailing,
    required VoidCallback onTap,
    double avatarRadius = 24,
    double padding = 12,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.blue.shade100,
      margin: EdgeInsets.symmetric(vertical: padding / 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding / 2,
        ),
        leading: CircleAvatar(
          radius: avatarRadius,
          backgroundImage: user.photoBase64 != null
              ? MemoryImage(_decodeBase64(user.photoBase64!))
              : null,
          backgroundColor: Colors.blue.shade200,
          child: user.photoBase64 == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _openProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId, isCurrentUser: false),
      ),
    );
  }

  Uint8List _decodeBase64(String base64String) => base64.decode(base64String);
}
