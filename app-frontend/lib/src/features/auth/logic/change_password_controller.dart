import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final changePasswordControllerProvider =
    NotifierProvider<ChangePasswordController, AsyncValue<String?>>(
  ChangePasswordController.new,
);

class ChangePasswordController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    return const AsyncData(null);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() {
      return authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    });
  }

  Future<void> setPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncLoading();
    final authRepository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() {
      return authRepository.setPassword(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    });
  }
}
