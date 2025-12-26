import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> loginUser(
      {required String email, required String password}) async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    state = await AsyncValue.guard(() async {
      final loginResponse =
          await authRepository.login(email: email, password: password);

      // ✅ FIX 1: Save both Token AND Session ID
      await storageService.saveAccessToken(loginResponse.accessToken);
      if (loginResponse.sessionId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('session_id', loginResponse.sessionId!);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', false);

      ref.read(authControllerProvider.notifier).refreshStatus();
    });
  }

  Future<void> loginAsGuest() async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    state = await AsyncValue.guard(() async {
      final String guestToken = await authRepository.getGuestToken();
      await storageService.saveAccessToken(guestToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', true);
      await prefs.remove('session_id'); // Guests don't have sessions

      ref.read(authControllerProvider.notifier).refreshStatus();
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncData(null);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final loginResponse =
          await authRepository.loginWithGoogle(googleAuth.idToken!);

      // ✅ FIX 2: Save Session ID for Google Users
      await storageService.saveAccessToken(loginResponse.accessToken);
      if (loginResponse.sessionId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('session_id', loginResponse.sessionId!);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', false);

      ref.read(authControllerProvider.notifier).refreshStatus();
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout(BuildContext context) async {
    final storageService = ref.read(secureStorageServiceProvider);
    final authRepository = ref.read(authRepositoryProvider);
    final prefs = await SharedPreferences.getInstance();

    // ✅ FIX 3: Get Session ID and terminate on server
    final int? sessionId = prefs.getInt('session_id');
    if (sessionId != null) {
      print("🔹 Terminating Session ID: $sessionId on server...");
      await authRepository.logout(sessionId);
    }

    // Local Cleanup
    await _googleSignIn.signOut();
    await storageService.clearAll();
    await prefs.remove('is_guest_mode');
    await prefs.remove('session_id');

    // ✅ FIX 4: Dismiss the loading dialog before navigating
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Pops the spinner

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
    ref.invalidateSelf();
  }
}
