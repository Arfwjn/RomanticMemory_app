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

  void checkAuthStatus() {
    final userId = firebaseService.getCurrentUserId();
    if (userId != null) {
      // User is logged in
      // Fetch user data if needed
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      isLoading(true);
      errorMessage(null);
      
      final user = await firebaseService.signUp(email, password, displayName);
      if (user != null) {
        currentUser(user);
        return true;
      }
      return false;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      isLoading(true);
      errorMessage(null);
      
      final user = await firebaseService.signIn(email, password);
      if (user != null) {
        currentUser(user);
        return true;
      }
      return false;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await firebaseService.signOut();
      currentUser(null);
    } catch (e) {
      errorMessage(e.toString());
    }
  }

  bool get isAuthenticated => currentUser.value != null;
}
