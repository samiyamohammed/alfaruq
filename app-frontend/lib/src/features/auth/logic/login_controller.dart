import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<void>>(
  LoginController.new,
);

class LoginController extends Notifier<AsyncValue<void>> {
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

      // 3. Save Session ID (NEW)
      if (loginResponse.sessionId != null) {
        await storageService.saveSessionId(loginResponse.sessionId!);
      }
    });
  }

  // --- 2. GOOGLE LOGIN ---
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    try {
      await _googleSignIn.signOut(); // Force account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = const AsyncData(null);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null)
        throw Exception("Failed to retrieve Google ID Token");

      // API Call
      final loginResponse = await authRepository.loginWithGoogle(idToken);

      // Save Token
      await storageService.saveAccessToken(loginResponse.accessToken);

      // Save Session ID (NEW)
      if (loginResponse.sessionId != null) {
        await storageService.saveSessionId(loginResponse.sessionId!);
      }

      state = const AsyncData(null);
    } catch (e, stack) {
      _googleSignIn.signOut();
      state = AsyncValue.error(e, stack);
    }
  }

  // --- 3. GUEST LOGIN ---
  Future<void> loginAsGuest() async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    state = await AsyncValue.guard(() async {
      final String guestToken = await authRepository.getGuestToken();
      await storageService.saveAccessToken(guestToken);
      // Guest usually doesn't have a sessionId to store, or logic differs
    });
  }

  // --- 4. LOGOUT (UPDATED) ---
  Future<void> logout(BuildContext context) async {
    final storageService = ref.read(secureStorageServiceProvider);
    final authRepository = ref.read(authRepositoryProvider);

    try {
      // 1. Get Session ID from storage
      final int? sessionId = await storageService.getSessionId();

      // 2. Call Server Logout API if session exists
      if (sessionId != null) {
        print("Logging out session: $sessionId");
        await authRepository.logout(sessionId);
      }

      // 3. Sign out from Google (Local)
      await _googleSignIn.signOut();

      // 4. Delete Local Data (Tokens & IDs)
      await storageService.clearAll();

      // 5. Navigate IMMEDIATELY
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

      // 6. Reset Controller State
      Future.delayed(const Duration(milliseconds: 200), () {
        ref.invalidateSelf();
      });
    } catch (e) {
      debugPrint("Logout Error: $e");
      // Fallback: Force local logout even if server/google fails
      await storageService.clearAll();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
