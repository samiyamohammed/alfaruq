import 'package:al_faruk_app/src/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor({required SecureStorageService storageService})
      : _storageService = storageService;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final noAuthRoutes = [
      '/auth/login',
      '/auth/register',
      '/auth/google-mobile',
      '/auth/forgot-password',
      '/auth/guest-token', // Bypass for guest token request
    ];

    if (noAuthRoutes.any((route) => options.path.contains(route))) {
      return handler.next(options);
    }

    final token = await _storageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If we get a 401 (Unauthorized), it means the token expired
    if (err.response?.statusCode == 401) {
      await _storageService.clearAll();
    }
    return handler.next(err);
  }
}
