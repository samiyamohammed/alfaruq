// lib/src/core/services/auth_interceptor.dart

import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor({required SecureStorageService storageService})
      : _storageService = storageService;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // print('Intercepting request path: "${options.path}"'); // Optional: Comment out to clean up logs

    // --- FIX: ADD GOOGLE ROUTE HERE ---
    // Adding '/auth/google-mobile' tells the interceptor:
    // "Don't look for a token for this request, it's a login attempt."
    final noAuthRoutes = [
      '/auth/login',
      '/auth/register',
      '/auth/google-mobile',
      '/auth/forgot-password',
    ];

    // Check if the current path matches any of the noAuthRoutes
    // We use .contains or .endsWith to be safe depending on your exact API structure
    if (noAuthRoutes.any((route) => options.path.contains(route))) {
      // print('Path is a public route. Passing without token.');
      return handler.next(options);
    }

    // print('Path is a protected route. Attempting to add token.');
    final token = await _storageService.getToken();

    if (token != null) {
      // print('Token found. Adding to headers.');
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      // print('No token found.');
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // print('Interceptor caught an error: ${err.response?.statusCode} on path "${err.requestOptions.path}"');

    final noAuthRoutes = [
      '/auth/login',
      '/auth/register',
      '/auth/google-mobile',
    ];

    if (err.response?.statusCode == 401) {
      if (!noAuthRoutes
          .any((route) => err.requestOptions.path.contains(route))) {
        await _storageService.deleteToken();
        print('Auth Error: Token is invalid. User needs to log in again.');
      }
    }

    return handler.next(err);
  }
}
