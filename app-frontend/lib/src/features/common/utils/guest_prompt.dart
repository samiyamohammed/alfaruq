import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_faruk_app/src/features/auth/logic/auth_controller.dart';
// Added the import for your LoginScreen
import 'package:al_faruk_app/src/features/auth/screens/login_screen.dart';

class GuestPrompt {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF151E32), // Deep Blue Background
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFFCFB56C), width: 1), // Gold Border
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Elegant Heart/Lock Icon
            const Icon(
              Icons.favorite_border_rounded,
              color: Color(0xFFCFB56C),
              size: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              "Sign In to Save Favorites",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Join us to keep track of your favorite movies, books, and tafsirs across all your devices.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // --- FUNCTIONAL LOGIN BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // 1. Close the bottom sheet
                  Navigator.pop(context);

                  // 2. Navigate to the Login Screen
                  // We use pushAndRemoveUntil to ensure the user starts a fresh auth flow
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCFB56C),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Log In / Sign Up",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Dismiss Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Maybe Later",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
