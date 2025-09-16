import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'user_repository.dart';

class AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final UserRepository userRepository;
  final SharedPreferences _prefs;

  AuthRepository(this.userRepository, this._prefs);

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  Future<User?> signUp({
    required String email,
    required String password,
    required String username,
    String? photoBase64,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user!;
    final appUser = User(
      uid: fbUser.uid,
      email: email,
      username: username,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      photoBase64: photoBase64,
    );

    await userRepository.createUser(appUser);
    await _saveAuthData(fbUser.uid, email);

    return appUser;
  }

  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user!;
    await _saveAuthData(fbUser.uid, email);
    return await userRepository.getUser(fbUser.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _clearAuthData();
  }

  fb.User? get currentUser => _auth.currentUser;

  bool get isAuthenticated => _prefs.getBool(_isLoggedInKey) ?? false;

  String? get userId => _prefs.getString(_userIdKey);

  String? get userEmail => _prefs.getString(_userEmailKey);

  Future<void> _saveAuthData(String userId, String email) async {
    await _prefs.setBool(_isLoggedInKey, true);
    await _prefs.setString(_userIdKey, userId);
    await _prefs.setString(_userEmailKey, email);
  }

  Future<void> _clearAuthData() async {
    await _prefs.remove(_isLoggedInKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
  }

  Future<bool> tryAutoLogin() async {
    if (isAuthenticated && userId != null) {
      try {
        return true;
      } catch (e) {
        await _clearAuthData();
        return false;
      }
    }
    return false;
  }
}
