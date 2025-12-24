import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyAccessToken = 'accessToken';
  static const String _keySessionId = 'sessionId'; // New Key

  // --- ACCESS TOKEN ---
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  // --- SESSION ID (NEW) ---
  Future<void> saveSessionId(int sessionId) async {
    // Store int as String
    await _storage.write(key: _keySessionId, value: sessionId.toString());
  }

  Future<int?> getSessionId() async {
    final val = await _storage.read(key: _keySessionId);
    if (val != null) {
      return int.tryParse(val);
    }
    return null;
  }

  // --- CLEAR ALL ---
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // --- BACKWARD COMPATIBILITY ---
  Future<void> saveToken(String token) async => saveAccessToken(token);
  Future<String?> getToken() async => getAccessToken();
  Future<void> deleteToken() async => clearAll();
}
