// lib/src/features/auth/logic/auth_controller.dart

import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Define the possible authentication states for our app.
enum AuthState {
  initial, // We haven't checked for a token yet.
  authenticated, // The user has a valid token and is logged in.
  unauthenticated, // The user does not have a token and is logged out.
}

// 2. Define the provider for our AuthController.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// 3. Create the AuthController class.
class AuthController extends Notifier<AuthState> {
  // The build method sets the initial state and immediately checks the auth status.
  @override
  AuthState build() {
    // We start in the 'initial' state.
    // As soon as the controller is built, we'll check for a token.
    _checkAuthStatus();
    return AuthState.initial;
  }

  // A private method to check for a saved token in secure storage.
  Future<void> _checkAuthStatus() async {
    // Get the storage service from its provider.
    final storageService = ref.read(secureStorageServiceProvider);
    final token = await storageService.getToken();

    // Give a slight delay to avoid a jarring flash of the loading screen on fast devices.
    await Future.delayed(const Duration(milliseconds: 500));

    // Update the state based on whether a token was found.
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  // A public method to handle logging out.
  // This method already correctly returns a Future<void>, so it is awaitable.
  Future<void> logout() async {
    // Get the storage service.
    final storageService = ref.read(secureStorageServiceProvider);

    // Delete the token from secure storage.
    await storageService.deleteToken();

    // Update the state to unauthenticated. The AuthGate will automatically
    // react to this change and show the LoginScreen.
    state = AuthState.unauthenticated;
  }
}
