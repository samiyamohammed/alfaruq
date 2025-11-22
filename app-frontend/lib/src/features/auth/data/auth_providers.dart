// lib/src/features/auth/data/auth_providers.dart

import 'package:al_faruk_app/src/core/services/auth_interceptor.dart';
import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

// Provider 1: The Dio instance provider. (UPDATED)
final dioProvider = Provider<Dio>((ref) {
  // First, create the Dio instance with its base options.
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://69.62.109.18:5001/api', // Your backend base URL
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Second, get the storage service that our interceptor needs.
  final storageService = ref.watch(secureStorageServiceProvider);

  // Third, add our custom AuthInterceptor to Dio's list of interceptors.
  // This is the crucial step that activates our automated token handling.
  dio.interceptors.add(
    AuthInterceptor(storageService: storageService),
  );

  // Finally, return the configured Dio instance.
  return dio;
});

// Provider 2: The AuthRepository provider. (Unchanged, but shown for context)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio: dio);
});
