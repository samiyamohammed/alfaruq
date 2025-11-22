// lib/src/features/auth/screens/auth_gate.dart

import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the AuthController's state.
    final authState = ref.watch(authControllerProvider);

    // Use a switch statement to decide which widget to show.
    switch (authState) {
      case AuthState.authenticated:
        // If authenticated, show the main content of the app.
        return const MainScreen();
      case AuthState.unauthenticated:
        // If not authenticated, show the login screen.
        return const LoginScreen();
      case AuthState.initial:
        // While we are checking for a token, show a loading spinner.
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}
