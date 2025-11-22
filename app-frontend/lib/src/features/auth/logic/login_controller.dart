// lib/src/features/auth/logic/login_controller.dart

import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<void>>(
  LoginController.new,
);

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    final authRepository = ref.read(authRepositoryProvider);
    final storageService = ref.read(secureStorageServiceProvider);

    state = await AsyncValue.guard(() async {
      // Step 1: Call the repository to log in.
      final loginResponse = await authRepository.login(
        email: email,
        password: password,
      );

      // Step 2: On success, save the token securely.
      await storageService.saveToken(loginResponse.accessToken);
    });
  }
}
