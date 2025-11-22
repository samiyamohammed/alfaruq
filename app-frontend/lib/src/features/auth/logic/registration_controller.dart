// lib/src/features/auth/logic/registration_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

// This provider creates and exposes the RegistrationController.
// The UI will watch this provider to react to state changes (e.g., show a loading spinner).
// AsyncValue<void> is perfect for actions/mutations that don't return a value,
// as it elegantly handles loading and error states for us.
final registrationControllerProvider =
    NotifierProvider<RegistrationController, AsyncValue<void>>(
  RegistrationController.new,
);

class RegistrationController extends Notifier<AsyncValue<void>> {
  // The build method is required by Notifier. It sets the initial state.
  @override
  AsyncValue<void> build() {
    // The initial state is 'data(null)', meaning not loading and no error.
    return const AsyncData(null);
  }

  // This is the single public method the UI will call to start the registration process.
  Future<void> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    // Step 1: Immediately set the state to loading. The UI will listen and show a progress indicator.
    state = const AsyncLoading();

    // Step 2: Read the repository from its provider. `ref.read` is used to get a provider's
    // value once inside a function.
    final authRepository = ref.read(authRepositoryProvider);

    // Step 3: Handle the business logic of splitting the full name.
    // This is a simple implementation. A more robust solution might handle middle names.
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Step 4: Call the repository and update the state based on the result.
    // `AsyncValue.guard` is a Riverpod helper that runs a Future and automatically
    // catches any errors, putting them into an AsyncError state for us. This is
    // a very clean way to handle try/catch blocks for state management.
    state = await AsyncValue.guard(() {
      return authRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: password, // The API requires a confirmation password.
      );
    });
  }
}
