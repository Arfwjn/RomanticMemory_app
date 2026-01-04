import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';

class AuthController extends GetxController {
  final firebaseService = FirebaseService();

  final isLoading = false.obs;
  final currentUser = Rx<User?>(null);
  final errorMessage = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  /// Check if user is already logged in
  void checkAuthStatus() async {
    try {
      final isLoggedIn = await firebaseService.isLoggedIn();
      if (isLoggedIn) {
        // Load user data from SharedPreferences
        final userId = firebaseService.getCurrentUserId();
        if (userId != null) {
          // Create a basic user object
          // Note: In production, you'd fetch full user data from database
          currentUser(User(
            id: userId,
            email: 'user@example.com', // You can store this in SharedPrefs too
            displayName: 'User',
          ));
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
    }
  }

  /// Sign up new user
  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      isLoading(true);
      errorMessage(null);

      final user = await firebaseService.signUp(email, password, displayName);
      if (user != null) {
        currentUser(user);
        return true;
      }

      errorMessage('Failed to create account');
      return false;
    } catch (e) {
      errorMessage('Sign up error: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Sign in existing user
  Future<bool> signIn(String email, String password) async {
    try {
      isLoading(true);
      errorMessage(null);

      final user = await firebaseService.signIn(email, password);
      if (user != null) {
        currentUser(user);
        return true;
      }

      errorMessage('Failed to sign in');
      return false;
    } catch (e) {
      errorMessage('Sign in error: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await firebaseService.signOut();
      currentUser(null);
    } catch (e) {
      errorMessage('Sign out error: ${e.toString()}');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser.value != null;
}
