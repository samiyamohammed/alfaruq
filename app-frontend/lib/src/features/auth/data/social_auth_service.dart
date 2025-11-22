// // lib/src/features/auth/data/social_auth_service.dart

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:google_sign_in/google_sign_in.dart';

// class SocialAuthException implements Exception {
//   final String message;
//   SocialAuthException(this.message);
//   @override
//   String toString() => message;
// }

// class SocialAuthService {
//   // Initialize GoogleSignIn. You can also pass scopes if you need more data.
//   final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

//   Future<String?> signInWithGoogle() async {
//     try {
//       // 1. Trigger the native Google Sign-In prompt.
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       // 2. If the user cancels the prompt, googleUser will be null.
//       if (googleUser == null) {
//         return null; // User cancelled.
//       }

//       // 3. Get the authentication tokens from the successful sign-in.
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // 4. Return the access token. Your developer docs confirm this is the token your backend needs.
//       // If the backend ever changes to need the ID token, you would return `googleAuth.idToken`.
//       return googleAuth.accessToken;
//     } catch (e) {
//       // It's helpful to print the actual error for debugging.
//       print('Google Sign-In Error: $e');
//       // Then throw a user-friendly exception.
//       throw SocialAuthException(
//           'An error occurred during Google Sign-In. Please try again.');
//     }
//   }

//   Future<void> signOutFromGoogle() async {
//     // This signs the user out of the Google account in the app.
//     await _googleSignIn.signOut();
//   }
// }

// // Provider for our new service.
// final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
//   return SocialAuthService();
// });
