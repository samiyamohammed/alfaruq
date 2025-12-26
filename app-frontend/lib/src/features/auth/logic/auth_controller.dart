import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthState {
  initial,
  authenticated,
  guest, // Added: Formal state for 'Skip' users
  unauthenticated,
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuthStatus();
    return AuthState.initial;
  }

  Future<void> _checkAuthStatus() async {
    final storageService = ref.read(secureStorageServiceProvider);
    final prefs = await SharedPreferences.getInstance();

    final token = await storageService.getAccessToken();
    final isGuest = prefs.getBool('is_guest_mode') ?? false;

    await Future.delayed(const Duration(milliseconds: 500));

    if (token != null) {
      // If we have a token, check if it's a guest token or real user token
      state = isGuest ? AuthState.guest : AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  // Used by LoginController to tell the app a new user (or guest) arrived
  void refreshStatus() => _checkAuthStatus();

  Future<void> logout() async {
    final storageService = ref.read(secureStorageServiceProvider);
    final prefs = await SharedPreferences.getInstance();

    await storageService.clearAll();
    await prefs.remove('is_guest_mode');

    state = AuthState.unauthenticated;
  }
}
