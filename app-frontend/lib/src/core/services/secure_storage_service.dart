import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyAccessToken = 'accessToken';

  // --- NEW METHODS (Required for LoginController & AuthInterceptor) ---

  // 1. Save Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  // 2. Get Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  // 3. Clear All (Logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // --- BACKWARD COMPATIBILITY (Keeps your old code working) ---

  // Maps old 'saveToken' to new 'saveAccessToken'
  Future<void> saveToken(String token) async => saveAccessToken(token);

  // Maps old 'getToken' to new 'getAccessToken'
  Future<String?> getToken() async => getAccessToken();

  // Maps old 'deleteToken' to new 'clearAll'
  Future<void> deleteToken() async => clearAll();
}
