import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart';
import 'package:al_faruk_app/src/features/main_scaffold/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    switch (authState) {
      case AuthState.authenticated:
      case AuthState.guest: // Both are allowed into the app
        return const MainScreen();
      case AuthState.unauthenticated:
        return const LoginScreen();
      case AuthState.initial:
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFDC34E)),
          ),
        );
    }
  }
}
