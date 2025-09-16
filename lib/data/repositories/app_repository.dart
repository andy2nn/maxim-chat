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

  AppRepository._({
    required this.authRepository,
    required this.userRepository,
    required this.chatRepository,
  });

  static Future<AppRepository> create() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final userRepo = UserRepository();
    final chatRepo = ChatRepository();
    final authRepo = AuthRepository(userRepo, sharedPreferences);

    return AppRepository._(
      authRepository: authRepo,
      userRepository: userRepo,
      chatRepository: chatRepo,
    );
  }

  Future<void> sendMessage(String senderId, String receiverId, Message msg) =>
      chatRepository.sendMessage(senderId, receiverId, msg);

  Stream<List<Message>> getMessages(String uid1, String uid2) =>
      chatRepository.getMessages(uid1, uid2);

  Stream<Map<String, dynamic>> getUserChats(String userId) =>
      chatRepository.getUserChats(userId);

  Future<void> createChat(String uid1, String uid2) =>
      chatRepository.createChat(uid1, uid2);

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

  bool get isAuthenticated => authRepository.isAuthenticated;

  String? get userId => authRepository.userId;

  String? get userEmail => authRepository.userEmail;

  Future<bool> tryAutoLogin() => authRepository.tryAutoLogin();
}
