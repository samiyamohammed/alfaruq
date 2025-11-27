// lib/src/features/auth/logic/registration_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

final registrationControllerProvider =
    NotifierProvider<RegistrationController, AsyncValue<void>>(
  RegistrationController.new,
);

class RegistrationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  // --- UPDATED: Accept First and Last Name separately ---
  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncLoading();

    final authRepository = ref.read(authRepositoryProvider);

    // Removed the name splitting logic.
    // We now pass the values directly.

    state = await AsyncValue.guard(() {
      return authRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: password,
      );
    });
  }
}
