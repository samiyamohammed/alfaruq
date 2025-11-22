// lib/src/features/profile/logic/profile_controller.dart

import 'package:al_faruk_app/src/core/models/user_model.dart';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider will fetch and cache the user's profile data.
// The `autoDispose` modifier is good practice to clean up the state when
// the profile screen is no longer visible.
final profileControllerProvider =
    FutureProvider.autoDispose<UserModel>((ref) async {
  // Get the repository from its provider.
  final authRepository = ref.watch(authRepositoryProvider);
  // Call the getProfile method and return the result.
  // Riverpod's FutureProvider will automatically handle the loading and error states for us.
  return authRepository.getProfile();
});
