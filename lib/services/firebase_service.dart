// lib/services/firebase_service.dart
// Stub service untuk compatibility - tidak digunakan secara aktif

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class FirebaseService {
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Check if user is logged in (always true untuk single user app)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get current user ID (hardcoded untuk single user)
  String? getCurrentUserId() {
    return 'local_user';
  }

  /// Sign up (auto-login untuk single user)
  Future<User?> signUp(
      String email, String password, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, 'local_user');

    return User(
      id: 'local_user',
      email: email,
      displayName: displayName,
    );
  }

  /// Sign in (auto-login untuk single user)
  Future<User?> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, 'local_user');

    return User(
      id: 'local_user',
      email: email,
      displayName: 'User',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }
}
