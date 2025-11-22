// lib/src/features/auth/logic/forgot_password_controller.dart

import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The state of this controller is the success message from the backend.
final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, AsyncValue<String?>>(
  ForgotPasswordController.new,
);

class ForgotPasswordController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    // Initial state is no data, not loading, no error.
    return const AsyncData(null);
  }

  Future<void> sendResetOtp({required String email}) async {
    // Set state to loading.
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);

    // Use AsyncValue.guard to automatically handle success and error states.
    state = await AsyncValue.guard(() {
      return authRepository.forgotPassword(email: email);
    });
  }
}
