import 'package:maxim_chat/data/models/chat.dart';

import 'auth_repository.dart';
import 'chat_repository.dart';
import 'user_repository.dart';
import '../models/user.dart';
import '../models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRepository {
  final AuthRepository authRepository;
  final UserRepository userRepository;
  final ChatRepository chatRepository;
  final SharedPreferences sharedPreferences;

  AppRepository({
    required this.authRepository,
    required this.userRepository,
    required this.chatRepository,
    required this.sharedPreferences,
  });

  factory AppRepository.createSync(SharedPreferences prefs) {
    final userRepo = UserRepository();
    final chatRepo = ChatRepository();
    final authRepo = AuthRepository(userRepo, prefs);

    return AppRepository(
      authRepository: authRepo,
      userRepository: userRepo,
      chatRepository: chatRepo,
      sharedPreferences: prefs,
    );
  }

  Future<void> sendMessage(Message message) =>
      chatRepository.sendMessage(message);

  Stream<List<Message>> getMessages(String chatId) =>
      chatRepository.getMessages(chatId);

  Stream<List<Chat>> getUserChats(String userId) =>
      chatRepository.getUserChats(userId);

  Future<Chat> createChat(
    List<String> members, {
    String name = '',
    bool isGroup = false,
  }) => chatRepository.createChat(members, name: name, isGroup: isGroup);

  Future<User?> signUp(
    String email,
    String password,
    String username, {
    String? photoBase64,
  }) => authRepository.signUp(
    email: email,
    password: password,
    username: username,
    photoBase64: photoBase64,
  );

  Future<User?> signIn(String email, String password) =>
      authRepository.signIn(email, password);

  Future<void> signOut() => authRepository.signOut();

  Stream<User?> userStream(String uid) => userRepository.userStream(uid);

  Future<void> updateUser(User user) => userRepository.updateUser(user);

  Future<void> sendFriendRequest(String fromUid, String toUid) =>
      userRepository.sendFriendRequest(fromUid, toUid);

  Future<void> acceptFriendRequest(String acceptorUid, String requesterUid) =>
      userRepository.acceptFriendRequest(acceptorUid, requesterUid);

  Future<void> rejectFriendRequest(String rejectorUid, String requesterUid) =>
      userRepository.rejectFriendRequest(rejectorUid, requesterUid);

  Future<void> removeFriend(String uid1, String uid2) =>
      userRepository.removeFriend(uid1, uid2);

  Future<void> cancelFriendRequest(String fromUid, String toUid) =>
      userRepository.cancelFriendRequest(fromUid, toUid);

  Stream<List<String>> friendsStream(String uid) =>
      userRepository.friendsStream(uid);

  Stream<List<String>> friendRequestsStream(String uid) =>
      userRepository.friendRequestsStream(uid);

  Stream<List<String>> friendSendsRequestsStream(String uid) =>
      userRepository.friendSendsRequestsStream(uid);

  Stream<List<User>> friendsWithDetailsStream(String uid) =>
      userRepository.friendsWithDetailsStream(uid);

  Stream<List<User>> searchUsers(String query) =>
      userRepository.searchUsers(query);

  bool get isAuthenticated => authRepository.isAuthenticated;

  String? get userId => authRepository.userId;

  String? get userEmail => authRepository.userEmail;

  Future<bool> tryAutoLogin() => authRepository.tryAutoLogin();
}
