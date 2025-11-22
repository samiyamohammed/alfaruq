// // lib/src/features/auth/logic/social_auth_controller.dart
// import 'dart:async';
// import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
// import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:app_links/app_links.dart'; // THE NEW PACKAGE
// import 'package:url_launcher/url_launcher.dart';
// import 'auth_controller.dart';

// final socialAuthControllerProvider =
//     NotifierProvider<SocialAuthController, AsyncValue<void>>(
//   SocialAuthController.new,
// );

// class SocialAuthController extends Notifier<AsyncValue<void>> {
//   late final AppLinks _appLinks;
//   StreamSubscription<Uri>? _linkSubscription;

//   @override
//   AsyncValue<void> build() {
//     if (!kIsWeb) {
//       _appLinks = AppLinks();
//       _handleIncomingLinks();
//     }

//     ref.onDispose(() {
//       _linkSubscription?.cancel();
//     });

//     return const AsyncData(null);
//   }

//   Future<void> signInWithGoogle() async {
//     state = const AsyncLoading();

//     if (kIsWeb) {
//       state = AsyncError(
//           'Google Sign-In via web redirect is not supported in this version.',
//           StackTrace.current);
//       return;
//     }

//     final authRepository = ref.read(authRepositoryProvider);

//     try {
//       final googleUrlString = await authRepository.getGoogleSignInUrl();
//       final url = Uri.parse(googleUrlString);

//       if (await canLaunchUrl(url)) {
//         await launchUrl(url, mode: LaunchMode.externalApplication);
//       } else {
//         throw 'Could not launch Google Sign-In.';
//       }
//     } catch (e, stack) {
//       state = AsyncError(e, stack);
//     }
//   }

//   void _handleIncomingLinks() {
//     _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
//       _processUri(uri);
//     });
//   }

//   void _processUri(Uri uri) {
//     if (uri.scheme == 'alfaruq' &&
//         uri.host == 'auth' &&
//         uri.path == '/callback') {
//       final token = uri.queryParameters['token'];
//       if (token != null && token.isNotEmpty) {
//         _loginWithToken(token);
//       } else {
//         state = AsyncError(
//             'Authentication failed. No token received.', StackTrace.current);
//       }
//     }
//   }

//   Future<void> _loginWithToken(String token) async {
//     final storageService = ref.read(secureStorageServiceProvider);
//     final mainAuthController = ref.read(authControllerProvider.notifier);

//     try {
//       await storageService.saveToken(token);
//       mainAuthController.state = AuthState.authenticated;
//       state = const AsyncData(null);
//     } catch (e, stack) {
//       state = AsyncError('Failed to save authentication token.', stack);
//     }
//   }
// }
