import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

// If you have a user provider, import it here to invalidate it later
// import 'package:al_faruk_app/src/features/user/data/user_providers.dart';

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<void>>(
  LoginController.new,
);

class LoginController extends Notifier<AsyncValue<void>> {
  // Update this with your actual Web Client ID from Firebase Console
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '619809373-92v14jvo2kke224oa9oq9tv56jhu7u16.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  // --- 1. EMAIL/PASSWORD LOGIN ---
  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    state = await AsyncValue.guard(() async {
      // 1. Call API
      final loginResponse = await authRepository.login(
        email: email,
        password: password,
      );

      // 2. Save Token
      await storageService.saveAccessToken(loginResponse.accessToken);

      // 3. (Optional) Refresh User Profile here if needed
      // ref.invalidate(currentUserProvider);
    });
  }

  // --- 2. GOOGLE LOGIN ---
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    try {
      // A. Force Account Picker (Fixes the "Auto-login" issue)
      await _googleSignIn.signOut();

      // B. Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the picker
        state = const AsyncData(null);
        return;
      }

      // C. Get ID Token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception("Failed to retrieve Google ID Token");
      }

      // D. Send to Backend
      final loginResponse = await authRepository.loginWithGoogle(idToken);

      // E. Save Token securely
      await storageService.saveAccessToken(loginResponse.accessToken);

      // F. (Optional) Refresh User Profile
      // ref.invalidate(currentUserProvider);

      state = const AsyncData(null);
    } catch (e, stack) {
      // Sign out locally if backend fails so user can try again
      _googleSignIn.signOut();
      state = AsyncValue.error(e, stack);
    }
  }

  // --- SAFE LOGOUT METHOD (FIXES THE CRASH) ---

  Future<void> logout(BuildContext context) async {
    final storageService = ref.read(secureStorageServiceProvider);

    try {
      // 1. Sign out from Google
      await _googleSignIn.signOut();

      // 2. Delete Local Token
      await storageService.deleteToken();

      // 3. Navigate IMMEDIATELY
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

      // 4. Reset ONLY the Login Controller
      // We removed the profile invalidation here.
      // Since the Profile Screen is being destroyed by the Navigator above,
      // we don't need to refresh its data. Doing so causes the Red Screen.
      Future.delayed(const Duration(milliseconds: 200), () {
        ref.invalidateSelf();
      });
    } catch (e) {
      debugPrint("Logout Error: $e");
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
