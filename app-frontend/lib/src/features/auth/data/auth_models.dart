// lib/src/features/auth/data/auth_models.dart

// A simple, plain Dart class for our login response.
// No code generation needed.
class LoginSuccessResponse {
  final String accessToken;

  // The constructor for the class.
  const LoginSuccessResponse({required this.accessToken});

  // A factory constructor to create an instance from a JSON map.
  factory LoginSuccessResponse.fromJson(Map<String, dynamic> json) {
    // --- THE BUG FIX ---
    // The key from the server is 'access_token' (snake_case), not 'accessToken'.
    // We now check for the correct key.
    if (json.containsKey('access_token') && json['access_token'] is String) {
      return LoginSuccessResponse(
        accessToken: json['access_token'],
      );
    } else {
      throw const FormatException(
          'Invalid JSON format for LoginSuccessResponse');
    }
  }
}
