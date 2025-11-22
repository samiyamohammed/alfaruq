// lib/src/features/auth/logic/reset_password_controller.dart
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final resetPasswordControllerProvider =
    NotifierProvider<ResetPasswordController, AsyncValue<String?>>(
  ResetPasswordController.new,
);

class ResetPasswordController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    return const AsyncData(null);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() {
      return authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    });
  }
}
